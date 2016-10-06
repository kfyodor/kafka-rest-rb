module KafkaRest
  class Message
    module Serializers
      class ActiveModel < Serializer
        def initialize(obj, opts, obj_options = {})
          super

          @klass = @opts.delete(:class) do
            raise MissingRequiredSerializerOption.new(self.class, 'class')
          end
        end

        def as_json
          @klass.new(@obj, @obj_options).as_json
        end
      end
    end
  end
end
