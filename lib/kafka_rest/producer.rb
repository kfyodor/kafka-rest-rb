require 'thread'

module KafkaRest
  class Producer
    @@lock = Mutex.new

    class << self
      def instance
        @@lock.synchronize do
          @instance ||= Producer.new(Client.new, lock: @@lock)
        end
      end
    end

    def initialize(client, opts = {})
      @lock = opts[:lock] || Mutex.new
      @client = client
      @key_schema_cache = {}
      @value_schema_cache = {}
    end

    def send!(message)
      resp = @client.topic_produce_message(
        message.topic,
        message.build_payload.merge
      ).body

      cache_schema_ids!(resp, message)
      resp['offset'].to_i
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
