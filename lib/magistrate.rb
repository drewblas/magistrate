$:.unshift File.dirname(__FILE__)

require 'magistrate/core_ext'
require 'magistrate/version'
require 'magistrate/supervisor'
require 'magistrate/process'

require 'logger'
# App wide logging system
LOGGER = Logger.new(STDOUT)

module Magistrate
  
end
