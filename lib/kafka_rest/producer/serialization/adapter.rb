module KafkaRest
  module Producer
    module Serialization
      class Adapter
        def initialize(*args)
          @args = args
        end

        def serialize(obj, options = {})
          raise NotImplementedError
        end
      end
    end
  end
end
