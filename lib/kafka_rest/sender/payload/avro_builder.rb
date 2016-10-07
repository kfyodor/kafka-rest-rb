module KafkaRest
  class Sender
    class Payload
      class AvroBuilder < Builder
        def build
          {
            key: @payload.key,
            value: @payload.value,
            key_schema: @payload.klass.get_key_schema,
            value_schema: @payload.klass.get_value_schema
          }
        end
      end
    end
  end
end
