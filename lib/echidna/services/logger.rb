require 'logger'

module Echidna
  class LogService
    attr_accessor :logger

    def initialize
      @logger = Logger.new('./logs/echidna.log', 'daily')
    end
  end
end
