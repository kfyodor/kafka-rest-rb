module KafkaRest
  module Sender
    class LogSender
      def initialize(logger = nil)
        @logger = logger || Logging.logger
      end

      def send!(msg)
        @logger.info "\n[Kafka REST] Produced a message: #{make_string(msg)}\n"
      end

      private

      def make_string(msg)
        [
          "\n\ttopic  = #{msg.topic}",
          "format = #{msg.format}",
          "key    = #{msg.payload[:key]}",
          "value  = #{msg.payload[:value]}",
        ].join "\n\t"
      end
    end
  end
end
