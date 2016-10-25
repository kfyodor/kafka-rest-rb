require 'kafka_rest/dsl'
require 'kafka_rest/producer/payload'

module KafkaRest
  module Producer
    DEFAULT_KEY_SCHEMA = "{\"type\": \"string\"}"

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
        }, default: DEFAULT_KEY_SCHEMA

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
      def build_message(obj, opts = {})
        Message.new(self, obj, opts)
      end

      def send!(obj, opts = {}, sender = nil)
        sender  = sender || KafkaRest.config.sender
        message = build_message(obj, opts)

        sender.send!(message)
      end
    end
  end
end
