module KafkaRest
  class Sender
    class Payload
      class AvroBuilder < Builder
        def build
          # http://avro.apache.org/docs/current/spec.html#json_encoding
          key = if default_key_schema? && @payload.key
                  "{\"string\": \"#{@payload.key}\"}"
                else
                  @payload.key
                end

          {
            key: key,
            value: @payload.value,
          }
        end

        private

        def default_key_schema?
          @payload.klass.get_key_schema == Producer::DEFAULT_KEY_SCHEMA
        end
      end
    end
  end
end
