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

    def self.logger=(l)
      @logger = l
    end

    def logger
      Logging.logger
    end
  end
end
