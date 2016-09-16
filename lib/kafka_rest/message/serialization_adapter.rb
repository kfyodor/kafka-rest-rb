module KafkaRest
  class Message
    class SerializationAdapter
      def initialize(obj, opts = {})
        @obj = obj
      end

      def serialize
        raise NotImplemented
      end
    end
  end
end
