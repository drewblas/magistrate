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
    def initialize(config_file, overrides = {})
      @workers = {}
      
      #File.expand_path('~')
      @config_file = config_file
      @config = File.open(config_file) { |file| YAML.load(file) }    
      @config.recursive_symbolize_keys!

      @uri = URI.parse @config[:monitor_url]
      @pid_path = @config[:pid_path] || File.join( 'tmp', 'pids' )
      
      FileUtils.mkdir_p(@pid_path) unless File.directory? @pid_path

      @config[:workers].each do |name,params|
        params[:pid_path] ||= @pid_path
        @workers[name] = Worker.new(name, params)
      end
      
      @loaded_from = nil
      @logs = []
      @verbose = overrides[:verbose]
      
      if @verbose
        require 'pp'
      end
    end

    def run(params = nil)
      log "Run started at: #{Time.now}"
      
      log "Starting Magistrate [[[#{self.name}]]] talking to [[[#{@config[:monitor_url]}]]]"
      set_target_states!
      
      # Pull in all already-running workers and set their target states
      @workers.each do |k, worker|
        worker.supervise!
        
        if worker.reset_target_state_to
          begin
            remote_request Net::HTTP::Post, "supervisors/#{self.name}/workers/#{worker.name}/set_target_state/#{worker.reset_target_state_to}"
          rescue StandardError => e
            log "Error resetting target_state for #{worker.name} to #{worker.reset_target_state_to}"
            log "Error: #{e}"
          end
        end
        
        if @verbose
          puts "==== Worker: #{k}"
          puts worker.logs.join("\n")
        end
      end

      log "Run Complete at: #{Time.now}" #This is only good in verbose mode, but that's ok

      send_status
    end
    
    # 
    def start(params = nil)
      worker = params
      log "Starting: #{worker}"
      @workers[worker.to_sym].supervise!
      
      # Save that we've requested this to be started
    end
    
    def stop(params = nil)
      worker = params
      log "Stopping: #{worker}"
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
      s = {
           :name => self.name,
           :pid_path => @pid_path,
           :monitor_url => @config[:monitor_url],
           :config_file => @config_file,
           :logs => @logs,
           :env => `env`.split("\n"),
           :workers => {}
          }
      
      @workers.each do |k,worker|
        s[:workers][k] = worker.status
      end
      
      s
    end
    
    def log(str)
      @logs << str
      puts str if @verbose
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
            log "Worker #{name} has an entry in the target_state but it's not listed in the local config file and will be ignored."
          end
        end
      end
    end
    
    # Gets and sets @target_states from the server
    # Automatically falls back to the local cache
    def load_remote_target_states!
      response = remote_request Net::HTTP::Get, "api/status/#{self.name}"
      
      if response.code == '200'
        log "Retrieved remote target states successfully"
        @loaded_from = :server
        @target_states = JSON.parse(response.body)
        save_target_states! # The double serialization here might not be best for performance, but will guarantee that the locally stored file is internally consistent
      else
        log "Server responded with error #{response.code} : [[[#{response.body}]]].  Using saved target states..."
        load_saved_target_states!
      end
      
    rescue StandardError => e
      log "Connection to server #{@config[:monitor_url]} failed."
      log "Error: #{e}"
      log "Using saved target states..."
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
      remote_request Net::HTTP::Post, "api/status/#{self.name}", { :status => JSON.generate(status) }
    rescue StandardError => e
      log "Sending status to #{@config[:monitor_url]} failed"
      log "Error: #{e}"
    end
    
    # This is the name that the magistrate_monitor will identify us as
    def name
      @_name ||= (@config[:supervisor_name_override] || "#{@config[:root_name]}-#{`hostname`.chomp}").gsub(/[^a-zA-Z0-9\-\_]/, ' ').gsub(/\s+/, '-').downcase
    end
    
    # Wrapper method for easy remote requests
    def remote_request(klass, path, form_data = {})
      log "#{klass} request to #{path}"
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.read_timeout = 30
      request = klass.new(@uri.request_uri + path)
      request.set_form_data(form_data) if klass == Net::HTTP::Post
      
      if @config[:http_username] && @config[:http_password]
        request.basic_auth @config[:http_username], @config[:http_password]
      end
      
      http.request(request)
    end
  end
end
