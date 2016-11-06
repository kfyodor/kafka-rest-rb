module KafkaRest
  class Worker
    module ErrorHandler
      include KafkaRest::Logging
      extend self

      def handle_error(ex)
        handlers = [LoggingErrorHandler] + KafkaRest.config.worker_error_handlers
        handlers.each do |handler|
          name = handler.respond_to?(:name) ? handler.name : handler

          begin
            if handler.respond_to?(:call)
              handler.call(ex)
            else
              logger.warn "[Kafka REST] Error handler #{name} must respond to `call`"
            end
          rescue => e
            logger.error "[Kafka REST] Error in #{name} handler while handling" +
                         " an exception #{ex.class}: #{e.class} (#{e.message})"
            logger.error e.backtrace.join("\n")
          end
        end
      end

      module LoggingErrorHandler
        include KafkaRest::Logging
        extend self

        def name
          "Logging error handler".freeze
        end

        def call(ex)
          logger.error "[Kafka REST] Got an error: #{ex.class} (#{ex.message})"
          logger.error ex.backtrace.join("\n")
        end
      end
    end
  end
end
