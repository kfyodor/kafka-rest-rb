module KafkaRest
  class Message
    module Serializers
      class Noop < Serializer
        def as_json
          @object
        end
      end
    end
  end
end
