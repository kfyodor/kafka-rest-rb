module KafkaRest
  module Producer
    class Payload
      class AvroBuilder < Builder
        # TODO: get rid of this
        def build
          {
            key: @payload.key,
            value: @payload.value,
          }
        end
      end
    end
  end
end
