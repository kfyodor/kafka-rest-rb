module KafkaRest
  module Producer
    module Serialization
      class Noop < Adapter
        def serialize(obj, opts = {})
          obj.to_s
        end
      end
    end
  end
end
