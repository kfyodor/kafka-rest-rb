module KafkaRest
  class Sender
    class Payload
      class Builder
        def initialize(payload)
          @payload = payload
        end

        def build
          raise NotImplementedError
        end
      end
    end
  end
end
