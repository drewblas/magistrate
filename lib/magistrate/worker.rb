require 'yaml'

module Magistrate
class Worker

  attr_reader :name, :daemonize, :start_cmd, :stop_cmd, :pid_file, :working_dir, :env, :logs, :reset_target_state_to, :bounces
  attr_accessor :target_state, :monitored

  def initialize(name, options = {})
    @name         = name
    @daemonize    = options[:daemonize]
    @working_dir  = options[:working_dir]
    @start_cmd    = options[:start_cmd]
    @pid_path     = options[:pid_path]
    
    if @daemonize
      @pid_file    = File.join(@pid_path, "#{@name}.pid")
      @status_file = File.join(@pid_path, "#{@name}.status")
      @stop_signal = options[:stop_signal] || 'TERM'
      @previous_status = load_previous_status
      @bounces     = @previous_status[:bounces] || 0
    else
      @stop_cmd     = options[:end_cmd]
      @pid_file     = options[:pid_file]
    end
    
    @stop_timeout = 5
    @start_timeout = 5
    
    @env = {}

    @target_state = :unknown
    @logs = []
  end
  
  def log(str)
    @logs << str
  end

  # Loads the number of times in a row this worker has been started without successfully staying running
  # This is stored in the @status_file
  def load_previous_status
    File.open(@status_file) { |file| YAML.load(file) } || {}
  rescue
    {}
  end

  def save_status
    if @status_file
      File.open(@status_file, "w") { |file| YAML.dump(status, file) } rescue nil
    end
  end

  def status
    {
      :state => self.state,
      :target_state => self.target_state,
      :pid => self.pid,
      :logs => @logs
    }
  end
  
  def running?
  end
  
  def state
    if @target_state == :unmonitored || @target_state == :unknown
      :unmonitored
    else
      if self.alive?
        :running
      else
        :stopped
      end
    end
  end
  
  # This is to be called when we first start managing a worker
  # It will check if the pid exists and if so, is the process responding OK?
  # It will take action based on the target state
  def supervise!
    log "Supervising.  Is: #{state}.  Target: #{@target_state}"
    if state != @target_state
      case @target_state
      when :forced_restart then
        @reset_target_state_to = :running
        log "Restart: Stopping, then Starting, then reporting new target_state of :running"
        stop
        start
      when :running then 
        start
        @bounces += 1
      when :stopped then stop
      end
    else
      @bounces = 0
    end

    save_status
  end
  
  def start
    if @daemonize
      log "Starting as daemon with double_fork"
      @pid = double_fork(@start_cmd)
      # TODO: Should check if the pid really exists as we expect
      write_pid
    else
      log "Starting as self-daemonizing with single_fork"
      @pid = single_fork(@start_cmd)
    end
    @pid
  end
  
  def stop
    if @daemonize
      signal(@stop_signal, pid)
        
      # Poll to see if it's dead
      @stop_timeout.times do
        begin
          ::Process.kill(0, pid)
        rescue Errno::ESRCH
          # It died. Good.
          log "Process stopped"
          return
        end
        
        sleep 1
      end
      
      signal('KILL', pid)
      log "Still alive after #{@stop_timeout}s; sent SIGKILL"
    else
      single_fork(@stop_cmd)
      ensure_stop
    end
  end
  
  # single fork self-daemonizing processes
  # we want to wait for them to finish
  def single_fork(command)
    pid = self.spawn(command)
    status = ::Process.waitpid2(pid, 0)
    exit_code = status[1] >> 8
    
    if exit_code != 0
      log "Command exited with non-zero code = #{exit_code}"
    end
    pid
  end
  
  def double_fork(command)
    pid = nil
    # double fork daemonized processes
    # we don't want to wait for them to finish
    r, w = IO.pipe
    begin
      opid = fork do
        STDOUT.reopen(w)
        r.close
        pid = self.spawn(command)
        puts pid.to_s # send pid back to forker
      end
      
      ::Process.waitpid(opid, 0)
      w.close
      pid = r.gets.chomp
    ensure
      # make sure the file descriptors get closed no matter what
      r.close rescue nil
      w.close rescue nil
    end
    
    pid
  end
  
  # Fork/exec the given command, returns immediately
  #   +command+ is the String containing the shell command
  #
  # Returns nothing
  def spawn(command)
    fork do
      ::Process.setsid

      dir = @working_dir || '/'
      Dir.chdir dir
      
      #$0 = command
      $0 = "Magistrate Worker: #{@name}"
      STDIN.reopen "/dev/null"
      
      STDOUT.reopen '/dev/null'
      STDERR.reopen STDOUT
      
      # if self.log_cmd
      #         STDOUT.reopen IO.popen(self.log_cmd, "a") 
      #       else
      #         STDOUT.reopen file_in_chroot(self.log), "a"        
      #       end
      #       
      #       if err_log_cmd
      #         STDERR.reopen IO.popen(err_log_cmd, "a") 
      #       elsif err_log && (log_cmd || err_log != log)
      #         STDERR.reopen file_in_chroot(err_log), "a"        
      #       else
      #         STDERR.reopen STDOUT
      #       end
      
      # close any other file descriptors
      3.upto(256){|fd| IO::new(fd).close rescue nil}

      if @env && @env.is_a?(Hash)
        @env.each do |key, value|
          ENV[key] = value.to_s
        end
      end

      exec command unless command.empty?
    end
  end
  
  # Ensure that a stop command actually stops the process. Force kill
  # if necessary.
  #
  # Returns nothing
  def ensure_stop
    log "Ensuring stop..."

    unless self.pid
      log "Stop called but pid is unknown"
      return
    end
    
    # Poll to see if it's dead
    @stop_timeout.times do
      begin
        signal(0)
      rescue Errno::ESRCH
        # It died. Good.
        return
      end
      
      sleep 1
    end
    
    # last resort
    signal('KILL')
    log "Still alive after #{@stop_timeout}s; sent SIGKILL"
  end
  
  # Send the given signal to this process.
  #
  # Returns nothing
  def signal(sig, target_pid = nil)
    target_pid ||= self.pid
    sig = sig.to_i if sig.to_i != 0
    log "Sending signal '#{sig}' to pid #{target_pid}"
    ::Process.kill(sig, target_pid) rescue nil
  end
  
  # Fetch the PID from pid_file. If the pid_file does not
  # exist, then use the PID from the last time it was read.
  # If it has never been read, then return nil.
  #
  # Returns Integer(pid) or nil
  def pid
    contents = File.read(@pid_file).strip rescue ''
    real_pid = contents =~ /^\d+$/ ? contents.to_i : nil
    
    if real_pid
      @pid = real_pid
      real_pid
    else
      @pid
    end
  end
  
  def write_pid
    File.open(@pid_file, 'w') do |f|
      f.write @pid
    end
  end
  
  def alive?
    if p = self.pid
      !!::Process.kill(0, p) rescue false
    else
      false
    end
  end

end
end