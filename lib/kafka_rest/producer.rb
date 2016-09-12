require 'thread'

module KafkaRest
  class Producer
    def initialize(client, schema_repo)
      @lock = Mutex.new
      @client = client
      @key_schema_cache = {}
      @value_schema_cache = {}
      @schema_repo = schema_repo
    end

    def send!(message)
      resp = @client.topic_produce_message(
        message.topic,
        message.build_payload.merge
      )

      cache_schema_ids!(resp, message)
    end

    private

    def cache_schema_ids!(resp, message)
      @lock.synchronize do
        if @key_schema_cache[topic].nil? && kid = resp['key_schema_id']
          @key_schema_cache[topic] = kid
        end

        if @value_schema_cache[topic].nil? && vid = resp['value_schema_id']
          @value_schema_cache[topic] = vid
        end
      end
    end
  end
end
