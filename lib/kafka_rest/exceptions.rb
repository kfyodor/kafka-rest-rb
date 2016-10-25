module KafkaRest
  class InvalidConfigValue < StandardError
    def initialize(name, val, msg = nil)
      message = "Invalid config for `#{name}`: #{val.to_s}"
      message << ". #{msg}" if msg

      super message
    end
  end

  class ClientError < StandardError
    attr_reader :body, :status, :error_code

    def initialize(resp)
      @body = resp.body
      @status = resp.status
      @error_code = @body['error_code']

      super "#{@body['message']}" +
            " (HTTP Status: #{@status}; " +
            "error code: #{@status})"
    end
  end

  class ProducerSendError < StandardError
  end

  class ConsumerError < StandardError; end
end
