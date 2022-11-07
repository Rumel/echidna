# frozen_string_literal: true

require 'logger'

module Echidna
  class LogService
    attr_accessor :file_logger, :console_logger

    def initialize
      @file_logger = Logger.new('./logs/echidna.log', 'daily')
      @console_logger = Logger.new($stdout)
    end

    %i[debug info warn error fatal].each do |level|
      define_method(level) do |msg|
        @file_logger.send(level, msg)
        @console_logger.send(level, msg)
      end
    end
  end
end
