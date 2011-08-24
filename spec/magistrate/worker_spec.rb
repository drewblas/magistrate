require "spec_helper"
require "magistrate/worker"

describe "Magistrate::Worker" do
  describe 'Rake-Like Worker' do
    before(:each) do
      @process = Magistrate::Worker.new(
        :name => 'rake_like_worker',
        :daemonize => true,
        :start_cmd => 'ruby spec/resources/rake_like_worker.rb'
      )
      
      stub(@process).spawn do 
        raise "Unexpected spawn call made...you don't want your specs actually spawning stuff, right?"
      end
    end
  
    describe 'state' do
      it 'should be unmonitored by default' do
        @process.state.should == :unmonitored
      end
      
      it 'should be unmonitored when unmonitored is the target state' do
        @process.target_state =  :unmonitored
        @process.state.should == :unmonitored
      end
      
      it 'should be stopped when target state other that unmonitored' do
        @process.target_state = :foo
        @process.state.should == :stopped
      end
    end
  end
  
  describe 'Self-Daemonizing Worker' do
    
  end
end