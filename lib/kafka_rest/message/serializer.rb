module KafkaRest
  class Message
    class Serializer
      class MissingRequiredSerializerOption < StandardError
        def initialize(klass, option_name)
          @message = "Option `:#{option_name}` is required for `#{klass.name}`"
          super
        end
      end

      def initialize(object, options = {})
        @object  = object
        @options = options
      end

      def as_json
        raise NotImplementedError
      end

      alias serialize as_json
    end
  end
end
