module KafkaRest
  module Message
    module ClassMethods
      def topic(topic)
        _topic = topic
      end

      def message_format(fmt)
        _message_format = fmt
      end
    end

    def self.included(base)
      base.cattr_accessor :_topic
      base.cattr_accessor :_message_format

      base.extend ClassMethods
    end

    def key
      nil
    end

    def serialize
      NotImplemented
    end

    def topic
      self.class._topic
    end

    def send!
      # KafkaRest::Core.send!(self)
    end

    def build_payload
      {
        key:   self.key,
        value: self.serialize
      }
    end
  end
end
