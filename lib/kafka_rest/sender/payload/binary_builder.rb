require 'base64'

module KafkaRest
  class Sender
    class Payload
      class BinaryBuilder < Builder
        def build
          {
            key: @payload.key,
            value: Base64.strict_encode64(@payload.value)
          }
        end
      end
    end
  end
end
