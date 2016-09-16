module KafkaRest
  class Message
    module Serializers
      class ActiveModel < Serializer
        def initialize(obj, opts)
          @klass = opts.delete(:class) do
            raise MissingRequiredSerializerOption.new(self.class, 'class')
          end

          @opts = opts
          @obj  = obj
        end

        def as_json
          @klass.new(@obj, @opts).as_json
        end
      end
    end
  end
end
