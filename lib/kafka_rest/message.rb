require 'kafka_rest/dsl'
require 'kafka_rest/message/serialization_adapter'

module KafkaRest
  class Message
    extend Dsl

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

    option :serializer, validate: ->(val) {
      val.is_a?(Class) && val < SerializationAdapter
    }, error_message: 'Serializer should be a child of `SerializationAdapter`'

    option :serializer_options, default: {}, validate: ->(val) {
      val.is_a?(Hash)
    }, error_message: 'Serializer options must be a Hash'

    attr_reader :object

    def initialize(object)
      @object  = object
    end

    def send!(opts = {})
      producer = opts.delete(:producer) || KafkaRest::Producer.instance
      producer.send!(self, opts)
    end

    def serialize_value
      serializer.new(@object, serializer_options).serialize
    end


    private

    def build_payload
      case self.message_format.to_sym
      when :avro
        build_avro_payload
      when :json
        build_json_payload
      when :binary
        build_binary_payload
      end
    end

    def build_avro_payload
      {
        key: get_key,
        value: serialize_value,
        key_schema: key_schema,
        value_schema: value_schema,
        topic: topic
      }
    end

    def build_binary_payload
      {
        key: get_key,
        value: Base64.strict_encode64(serialize_value),
        topic: topic
      }
    end

    def build_json_payload
      {
        key: get_key,
        value: serialize_value,
        topic: topic
      }
    end

    def get_key
      case key
      when NilClass
        nil
      when Symbol
        if self.respond_to?(key)
          send key
        elsif @object.respond_to?(key)
          @object.send(key) # Do we need to call this method on object at all?
        else
          raise "Unefined method `#{key}`"
        end
      when Proc
        key.call(@object)
      end
    end
  end
end
