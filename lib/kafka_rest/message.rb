require 'kafka_rest/dsl'
require 'kafka_rest/message/serializer'

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

    option :serializer, with_options: true, validate: ->(val) {
      val.is_a?(Class) && val < Serializer
    }, error_message: 'Serializer should be an ancestor of `KafkaRest::Message::Serializer`'

    attr_reader :object

    def initialize(object, opts = {})
      @object  = object
      @opts    = opts
    end

    def send!(opts = {})
      (opts[:producer] || KafkaRest::Producer.instance).send!(self)
    end

    def serialized_value
      serializer.new(@object, serializer_options, @opts).as_json
    end

    private

    def serializer
      self.class._serializer || KafkaRest.config.default_message_serializer
    end

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
        value: serialized_value,
        key_schema: key_schema,
        value_schema: value_schema
      }
    end

    def build_binary_payload
      {
        key: get_key,
        value: Base64.strict_encode64(serialized_value)
      }
    end

    def build_json_payload
      {
        key: get_key,
        value: serialized_value
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
