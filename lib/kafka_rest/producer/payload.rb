require 'kafka_rest/producer/payload/builder'
require 'kafka_rest/producer/payload/avro_builder'
require 'kafka_rest/producer/payload/json_builder'
require 'kafka_rest/producer/payload/binary_builder'

module KafkaRest
  module Producer
    class Payload
      attr_reader :klass

      def initialize(klass, obj, opts = {})
        @klass   = klass
        @obj     = obj
        @opts    = opts
        @builder = get_builder.new(self)

        @key       = @opts.delete(:key)
        @timestamp = @opts.delete(:timestamp)
        @partition = @opts.delete(:partition)
      end

      def build
        @builder.build.tap do |pl|
          @timestamp and pl[:timestamp] = @timestamp
          @partition and pl[:partition] = @partition
        end
      end

      def value
        @klass.get_serializer.serialize(@obj, @opts)
      end

      def key
        return @key if @key

        k = @klass.get_key

        case k
        when NilClass
          k
        when Symbol
          if inst.respond_to?(k)
            inst.send(k, @obj)
          elsif @obj.respond_to?(k)
            @obj.send(k)
          else
            raise NoMethodError.new("Undefined method \"#{k}\"")
          end
        when Proc
          k.call(@obj)
        end
      end

      private

      def get_builder
        case klass.get_format
        when :avro
          AvroBuilder
        when :json
          JsonBuilder
        when :binary
          BinaryBuilder
        end
      end

      def inst
        @inst ||= @klass.new
      end
    end
  end
end
