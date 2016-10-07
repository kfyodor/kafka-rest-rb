module KafkaRest
  class Sender
    class Payload
      class AvroBuilder < Builder
        # TODO: since schemas are not needed here,
        #       move this and json_builder to builder
        #       and keep only BinaryBuilder
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
