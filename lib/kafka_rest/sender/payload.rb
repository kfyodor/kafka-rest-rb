module KafkaRest
  class Sender
    class Payload
      attr_reader :klass

      def initialize(klass, obj, opts = {})
        @klass   = klass
        @obj     = obj
        @opts    = opts
        @builder = get_builder(klass)
      end

      def build
        @builder.build(self)
      end

      def value
        @klass.get_serializer.serialize(@obj, @opts)
      end

      def key
        k = @klass.get_key

        case k
        when NilClass
          k
        when Symbol
          if inst.respond_to?(k)
            inst.send(k, @obj)
          elsif
            @obj.respond_to?(k)
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
