require 'rubygems'
# Ugh, yaml for local serialization and json for over-the-wire serialization sucks.  
# But YAML doesn't go over the wire well and json doesn't support comments and makes for really bad local config files
# Almost makes me want to use XML ;)
require 'yaml'
require 'json'
require 'fileutils'
require 'net/http'
require 'uri'

module Magistrate
  class Supervisor    
    def initialize(config_file)
      @workers = {}
      
      #File.expand_path('~')
      
      FileUtils.mkdir_p(@pid_path) unless File.directory? @pid_path
      
      @config = File.open(config_file) { |file| YAML.load(file) }    
      @config.recursive_symbolize_keys!

      @uri = URI.parse @config[:monitor_url]
      @pid_path = @config[:pid_path] || File.join( 'tmp', 'pids' )

      @config[:workers].each do |k,v|
        v[:pid_path] ||= @pid_path
        @workers[k] = Process.new(k,v)
      end
      
      @loaded_from = nil
    end

    def run(params = nil)
      puts "Starting Magistrate [[[#{self.name}]]] talking to [[[#{@config[:monitor_url]}]]]"
      set_target_states!
      
      # Pull in all already-running workers and set their target states
      @workers.each do |k, worker|
        worker.supervise!
      end
      
      send_status
    end
    
    # 
    def start(params = nil)
      worker = params
      puts "Starting: #{worker}"
      @workers[worker.to_sym].supervise!
      
      # Save that we've requested this to be started
    end
    
    def stop(params = nil)
      worker = params
      puts "Stopping: #{worker}"
      @workers[worker.to_sym].stop
      
      # Save that we've requested this to be stopped
    end
    
    def list(params = nil)
      set_target_states!
      
      require 'pp'
      pp status
    end
    
    # Returns the actual hash of all workers and their status
    def status
      s = {}
      
      @workers.each do |k,process|
        s[k] = {
          :state => process.state,
          :target_state => process.target_state,
          :pid => process.pid
        }
      end
      
      s
    end
    
    protected
    
    # Loads the @target_states from either the remote server or local cache
    # Then sets all the worker target_states to the loaded values
    def set_target_states!(local_only = false)
      local_only ? load_saved_target_states! : load_remote_target_states!
      
      if @target_states && @target_states['workers']
        @target_states['workers'].each do |name, target|
          name = name.to_sym
          if @workers[name]
            @workers[name].target_state = target['target_state'].to_sym if target['target_state']
          else
            puts "Worker #{name} not found in local config"
          end
        end
      end
    end
    
    # Gets and sets @target_states from the server
    # Automatically falls back to the local cache
    def load_remote_target_states!
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.read_timeout = 30
      request = Net::HTTP::Get.new(@uri.request_uri + "api/status/#{self.name}")

      response = http.request(request)
      
      if response.code == '200'
        @loaded_from = :server
        @target_states = JSON.parse(response.body)
        save_target_states! # The double serialization here might not be best for performance, but will guarantee that the locally stored file is internally consistent
      else
        puts "Server responded with error #{response.code} : [[[#{response.body}]]].  Using saved target states..."
        load_saved_target_states!
      end
      
    rescue StandardError => e
      puts "Connection to server #{@config[:monitor_url]} failed."
      puts "Error: #{e}"
      puts "Using saved target states..."
      load_saved_target_states!
    end
    
    # Loads the @target_states variable from the cache file
    def load_saved_target_states!
      @loaded_from = :file
      @target_states = File.open(target_states_file) { |file| YAML.load(file) }
    end
    
    def save_target_states!
      File.open(target_states_file, "w") { |file| YAML.dump(@target_states, file) }
    end
    
    def target_states_file
      File.join @pid_path, 'target_states.yml'
    end
    
    # Sends the current system status back to the server
    # Currently only sends basic worker info, but could start sending lots more:
    # 
    def send_status
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.read_timeout = 30
      request = Net::HTTP::Post.new(@uri.request_uri + "api/status/#{self.name}")
      request.set_form_data({ :status => JSON.generate(status) })
      response = http.request(request)
    rescue StandardError => e
      puts "Sending status to #{@config[:monitor_url]} failed"
    end
    
    # This is the name that the magistrate_monitor will identify us as
    def name
      @_name ||= (@config[:supervisor_name_override] || "#{@config[:root_name]}-#{`hostname`.chomp}").gsub(/[^a-zA-Z0-9\-\_]/, ' ').gsub(/\s+/, '-').downcase
    end
  end
end