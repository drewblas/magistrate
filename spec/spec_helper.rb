require "rubygems"
require 'webmock/rspec'
require "rspec"
require "fakefs/safe"
#require "fakefs/spec_helpers"

$:.unshift File.expand_path("../../lib", __FILE__)

def mock_error(subject, message)
  mock_exit do
    mock(subject).puts("ERROR: #{message}")
    yield
  end
end

def mock_exit(&block)
  block.should raise_error(SystemExit)
end
# 
# def load_export_templates_into_fakefs(type)
#   FakeFS.deactivate!
#   files = Dir[File.expand_path("../../data/export/#{type}/**", __FILE__)].inject({}) do |hash, file|
#     hash.update(file => File.read(file))
#   end
#   FakeFS.activate!
#   files.each do |filename, contents|
#     File.open(filename, "w") do |f|
#       f.puts contents
#     end
#   end
# end
# 
# def example_export_file(filename)
#   FakeFS.deactivate!
#   data = File.read(File.expand_path("../resources/export/#{filename}", __FILE__))
#   FakeFS.activate!
#   data
# end

RSpec.configure do |config|
  config.color_enabled = true
  #config.include FakeFS::SpecHelpers
  config.mock_with :rr
  
  config.before(:suite) do
    f = 'tmp/pids/target_states.yml'
    File.delete(f) if File.exist?(f)
  end
end
