require 'kafka_rest/dsl'

module KafkaRest
  module Producer
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        extend Dsl

        option :topic, required: true

        option :format, default: KafkaRest.config.message_format, validate: ->(v){
          %w(json binary avro).include?(v.to_s)
        }, error_message: 'Format must be `avro`, `json` or `binary`.'


        option :key_schema, validate: ->(v){
          v.is_a?(Symbol) || v.is_a?(String) || v.is_a?(Proc)
        }, default: '["null", "string"]'

        option :value_schema, validate: ->(v){
          v.is_a?(Symbol) || v.is_a?(String) || v.is_a?(Proc)
        }

        option :key, validate: ->(val) {
          if val
            val.is_a?(Symbol) || val.is_a?(Proc)
          else
            true
          end
        }

        option :serialization_adapter, validate: ->(val){
          if val
            val.is_a?(Class) && val < Serialization::Adapter
          else
            true
          end
        }, default: KafkaRest.config.serialization_adapter

        option :serializer

        class << base
          # right away override default get_serializer and get_value_schema
          def get_serializer
            @serializer_inst ||= get_serialization_adapter.new @serializer
          end

          def get_value_schema
            if get_format.to_s == 'avro' && @value_schema.nil?
              raise 'Format `avro` requires providing `value_schema`'
            end

            @value_schema
          end
        end
      end
    end

    module ClassMethods
      def send!(obj, opts = {}, producer = nil)
        (producer || KafkaRest::Producer::Sender.instance).send!(self, obj, opts)
      end
    end
  end
end
