require "spec_helper"
require "magistrate"

describe Magistrate do

  describe "VERSION" do
    subject { Magistrate::VERSION }
    it { should be_a String }
  end

end
