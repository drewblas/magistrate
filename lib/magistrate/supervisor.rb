require 'yaml'
require 'fileutils'
require 'net/http'
require 'uri'

module Magistrate
  class Supervisor
    def initialize(config_file)
      @workers = {}
      
      #File.expand_path('~')
      @pid_path = File.join( 'tmp', 'pids' )
      
      FileUtils.mkdir_p(@pid_path) unless File.directory? @pid_path
      
      @config = File.open(config_file) { |file| YAML.load(file) }.symbolize_keys!
      @config[:workers].symbolize_keys!

      @uri = URI.parse @config[:monitor_url]

      @config[:workers].each do |k,v|
        v.symbolize_keys!
        @workers[k] = Process.new(k,v)
      end
      
      @loaded_from = nil
    end

    def run(params = nil)
      puts "Starting Magistrate"
      # Download latest instructions
      
      # Pull in all already-running workers
      
      @workers.each do |k, worker|
        worker.supervise!
      end
      
      # Start all new workers
      
      # Execute all commands
      
      # Report status
    end
    
    def start(params = nil)
      worker = params
      puts "Starting: #{worker}"
      @workers[worker.to_sym].supervise!
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
    
    protected
    
    def set_target_states!(local_only = false)
      @target_states = local_only ? load_saved_target_states : load_remote_target_states
      
      @target_states['workers'].each do |name, state|
        begin
          @workers[name.to_sym].target_state = state.to_sym
        rescue
          puts "Worker #{name} not found in local config"
        end
      end
    end
    
    def load_remote_target_states
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.read_timeout = 30
      request = Net::HTTP::Get.new(@uri.request_uri + 'api/target_states')

      response = http.request(request)
      @loaded_from = :server
      
      return YAML.load(response.body)
      
      rescue StandardError => e
        puts "Connection to server #{@config[:monitor_url]} failed.  Using saved target states..."
        load_saved_target_states
    end
    
    def load_saved_target_states
      @loaded_from = :file
      @target_states = File.open(target_states_file) { |file| YAML.load(file) }
    end
    
    def save_target_states
      File.open(target_states_file, "w") { |file| YAML.dump(obj, file) }
    end
    
    def target_states_file
      File.join @pid_path, 'target_states.yml'
    end
    
    def send_status
      
    end
    
    # Returns the actual hash of all workers and their status
    def status
      s = {}
      
      @workers.each do |k,process|
        s[k] = {
          :state => process.state,
          :target_state => process.target_state
        }
      end
      
      s
    end
  end
end