module KafkaRest
  class Message
    class Serializer
      class MissingRequiredSerializerOption < StandardError
        def initialize(klass, option_name)
          @message = "Option `:#{option_name}` is required for `#{klass.name}`"
          super
        end
      end

      def initialize(object, options = {}, obj_options = {})
        @object      = object
        @options     = options
        @obj_options = obj_options
      end

      def as_json
        raise NotImplementedError
      end

      alias serialize as_json
    end
  end
end
