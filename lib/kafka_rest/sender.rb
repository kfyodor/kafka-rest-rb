require 'thread'

module KafkaRest
  module Sender
    require 'kafka_rest/sender/kafka_sender'
    require 'kafka_rest/sender/log_sender'
    require 'kafka_rest/sender/test_sender'

    def self.valid?(sender)
      sender.respond_to? :send!
    end
  end
end
