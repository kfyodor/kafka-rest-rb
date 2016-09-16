require 'faraday'
require 'faraday_middleware/response_middleware'
require 'oj'

module KafkaRest
  class Client
    class KafkaRestClientException < StandardError
      attr_reader :body, :status

      def initialize(resp)
        @body = resp.body
        @status = resp.status

        super "#{@body['message']}" +
              " (HTTP Status: #{@status}; " +
              "error code: #{@body['error_code']})"
      end
    end

    class DefaultHeaders < Faraday::Middleware
      def initialize(app = nil, default_headers = {})
        @default_headers = default_headers
        super(app)
      end

      def call(env)
        env[:request_headers] = @default_headers.merge env[:request_headers]
        @app.call(env)
      end
    end

    class JsonRequest < Faraday::Middleware
      def call(env)
        if env[:body]
          env[:body] = Oj.dump env[:body], mode: :compat, symbol_keys: false
        end

        @app.call(env)
      end
    end

    class JsonResponse < FaradayMiddleware::ResponseMiddleware
      define_parser do |body|
        Oj.load(body)
      end
    end

    class RaiseException < FaradayMiddleware::ResponseMiddleware
      def call(env)
        response = @app.call(env)
        response.on_complete do
          unless response.success?
            raise KafkaRestClientException.new(response)
          end
        end
      end
    end

    Faraday::Request.register_middleware(
      default_headers: DefaultHeaders,
      encode_json: JsonRequest
    )

    Faraday::Response.register_middleware(
      decode_json: JsonResponse,
      raise_exception: RaiseException
    )
  end
end
