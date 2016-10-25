module KafkaRest
  module Sender
    class TestSender
      attr_reader :messages

      def initialize
        @lock     = Mutex.new
        @messages = {}
      end

      def send!(message)
        @lock.synchronize do
          topic = message.topic
          @messages[topic] ||= []
          @messages[topic] << message
        end
      end

      def last_for(topic)
        @messages[topic].last
      end

      def reset!
        @messages = {}
      end
    end
  end
end
