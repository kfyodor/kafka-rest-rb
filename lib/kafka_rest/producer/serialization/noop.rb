module KafkaRest
  module Producer
    module Serialization
      class Noop
        def serialize(obj, opts = {})
          obj.to_s
        end
      end
    end
  end
end
