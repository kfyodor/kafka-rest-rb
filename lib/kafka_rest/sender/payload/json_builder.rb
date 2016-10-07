module KafkaRest
  module Producer
    class Payload
      class JsonBuilder < Builder
        def build
          {
            key: @payload.key,
            value: @payload.value
          }
        end
      end
    end
  end
end
