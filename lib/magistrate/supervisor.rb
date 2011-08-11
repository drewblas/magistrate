require 'yaml'
require 'fileutils'

module Magistrate
  class Supervisor
    def initialize(config_file)
      @workers = {}
      
      #File.expand_path('~')
      @pid_path = File.join( 'tmp', 'pids' )
      
      FileUtils.mkdir_p(@pid_path) unless File.directory? @pid_path
      
      @config = File.open(config_file) { |file| YAML.load(file) }.symbolize_keys!

      @config.each do |k,v|
        v.symbolize_keys!
        @workers[k] = Process.new(v)
      end
    end

    def start
      puts "Starting Magistrate"
      # Pull in all already-running workers
      
      @workers.each do |k, worker|
        worker.supervise!
      end
      # Start all new workers
    end
    
    def stop
      puts "Stopping Magistrate"
      # Send kill to all active workers
      # Send term to all active workers
    end
    
    def list
      
    end
    
    def status
      
    end
    
    
  end
end