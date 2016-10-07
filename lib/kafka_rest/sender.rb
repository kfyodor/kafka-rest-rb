require 'thread'

module KafkaRest

  class Sender
    @@lock = Mutex.new

    class << self
      def instance
        @@lock.synchronize do
          @instance ||= self.new(Client.new, lock: @@lock)
        end
      end
    end

    def initialize(client, opts = {})
      @lock = opts[:lock] || Mutex.new
      @client = client
      @key_schema_cache = {}
      @value_schema_cache = {}
    end

    def send!(klass, obj, opts = {})
      payload = Payload.new(klass, obj, opts).build

      resp = @client.topic_produce_message(
        klass.get_topic,
        payload,
        klass.get_format
      ).body

      cache_schema_ids!(resp, payload)

      resp['offset'].to_i
    end

    private

    def cache_schema_ids!(resp, message)
      return unless message.message_format.to_sym == :avro
      topic = message.topic

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
