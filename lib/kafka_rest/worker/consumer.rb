module KafkaRest
  class Worker
    class Consumer
      # Does the actual work of working with kafka-rest api,
      # processing messages and commiting offsets.
      # This class is not thread-safe. In threaded environments
      # it must be used within KafkaRest::Worker::ConsumerManager

      include KafkaRest::Logging
      extend Forwardable

      def_delegators :@instance,
                     :topic, :group_name, :poll_delay, :auto_commit,
                     :offset_reset, :format, :max_bytes

      def initialize(consumer, client)
        @instance = consumer.new
        @client = client
        @id = nil
        @uri = nil
      end

      def add!
        params = {}
        params[:auto_commit_enable] = auto_commit if auto_commit
        params[:auto_offset_reset] = offset_reset if offset_reset
        params[:format] = format if format

        resp = @client.consumer_add(group_name, params)

        @id  = resp.body['instance_id']
        @uri = resp.body['base_uri']

        logger.info "[Kafka REST] Added consumer #{@id}"
      end

      def remove!
        resp = @client.consumer_remove(group_name, @id)
        @id    = nil
        @uri   = nil

        logger.info "[Kafka REST] Removed consumer #{@id}"
      end

      def poll!
        params = {}
        params[:format] = format if format
        params[:max_bytes] = max_bytes if max_bytes

        logger.debug "[Kafka REST] Polling consumer #{@id}..."

        resp = @client.consumer_consume_from_topic(group_name, @id, topic, params)
        process_messages(resp.body)
      end

      def commit!
        @client.consumer_commit_offsets(group_name, @id)
      end

      def added?
        !@id.nil?
      end

      private

      def process_messages(messages)
        if messages.any?
          messages.each do |msg|
            logger.debug "[Kafka REST] Consumer #{@id} got message: #{msg}"
            @instance.receive ConsumerMessage.new(msg, topic)
          end

          logger.info "[Kafka REST] Consumer #{@id} processed #{messages.size} messages"

          commit! unless auto_commit

          true
        else
          false
        end
      end
    end
  end
end
