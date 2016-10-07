require 'kafka_rest/dsl'

module KafkaRest
  module Producer
    def self.included(base)
      base.extend Dsl
      base.class_eval do
        option :topic, required: true

        option :message_format, default: 'json', validate: ->(val) {
          %w(json binary avro).include?(val.to_s)
        }, error_message: 'Format must be `avro`, `json` or `binary`.'

        option :key_schema, default: '{"type": "string"}', validate: ->(val) {
          val.is_a?(Symbol) || val.is_a?(String) || val.is_a?(Proc)
        }

        option :value_schema, validate: ->(val) {
          val.is_a?(Symbol) || val.is_a?(String) || val.is_a?(Proc)
        }

        option :key, validate: ->(val) {
          if val
            val.is_a?(Symbol) || val.is_a?(Proc)
          else
            true
          end
        }

        option :serialization_adapter
        option :serializer
      end

      base.extend ClassMethods
    end

    module ClassMethods
      def get_serializer
        @serializer_inst ||= (
          get_serialization_adapter || KafkaRest.config.default_serialization_adapter
        ).new @serializer
      end

      def send!(obj, opts = {}, producer = nil)
        (producer || KafkaRest::Producer::Sender.instance).send!(self, obj, opts)
      end
    end
  end
end
