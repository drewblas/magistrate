require 'yaml'  # YAML for internal config and json for over-the-wire config.  Ugh!
require 'json'
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

      @uri = URI.parse @config[:url]

      @config[:workers].each do |k,v|
        v.symbolize_keys!
        @workers[k] = Process.new(k,v)
      end
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
    end
    
    def list(params = nil)
      @workers.each do |k, worker|
        state = worker.state
        
        puts "#{k}: #{worker.alive? ? 'Running' : 'Stopped'}"
      end
    end
    
    # Generates the exact status that will be sent to the server
    def status
      require 'pp'
      
      pp worker_status
    end
    
    protected
    
    def retrieve_target_states
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.read_timeout = 30
      request = Net::HTTP::Get.new(uri.request_uri + 'api/target_states')

      response = http.request(request)
      
      rescue Timeout::Error => e
        puts "Connection to server #{@config[:url]} failed.  Using target states"
        load_saved_target_states!
    end
    
    def load_saved_target_states!
      
    end
    
    def save_target_states
      
    end
    
    def send_status
      
    end
    
    # Returns the actual hash of all workers and their status
    def worker_status
      s = {}
      
      @workers.each do |k,process|
        
      end
    end
  end
end