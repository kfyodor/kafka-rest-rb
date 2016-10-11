module KafkaRest
  module Logging
    def self.logger
      @logger ||= (
        require 'logger'
        ::Logger.new(STDOUT).tap do |l|
          l.level = ::Logger::INFO
        end
      )
    end

    def self.logger=(logger)
      @logger = logger
    end

    def logger
      self.logger
    end
  end
end
