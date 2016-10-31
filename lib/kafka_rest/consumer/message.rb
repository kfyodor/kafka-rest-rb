module KafkaRest
  module Consumer
    class Message
      attr_reader :key, :value, :offset, :partition, :timestamp

      def initialize(payload, topic)
        @key = payload['key']
        @value = payload['value']
        @partition = payload['partition']
        @timestamp = payload['timestamp']
        @offset = payload['offset']
        @topic = topic
      end
    end
  end
end
