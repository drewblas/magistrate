require "spec_helper"
require "magistrate/supervisor"

describe "Magistrate::Supervisor" do
  before(:each) do
    @supervisor = Magistrate::Supervisor.new("spec/resources/example.yml")
  end
  
  it "should initialize correctly" do
    lambda { Magistrate::Supervisor.new("spec/resources/example.yml") }.should_not raise_error
  end
  
  it "should show basic status for its workers" do
    @supervisor.status.should == { :daemon_worker=>{:state=>:unmonitored, :target_state=>:unknown}, 
                                   :rake_like_worker=>{:state=>:unmonitored, :target_state=>:unknown} }
  end
  
#  it 'should'
end