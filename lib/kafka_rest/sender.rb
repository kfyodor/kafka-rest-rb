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

    attr_reader :key_schema_cache, :value_schema_cache


    # TODO: buffering???
    def initialize(client, opts = {})
      @lock = opts[:lock] || Mutex.new
      @client = client
      @key_schema_cache = {}
      @value_schema_cache = {}
    end

    # TODO: back-off retry if offset[i].errors is a retriable error
    def send!(klass, obj, opts = {})
      topic   = klass.get_topic.to_s
      format  = klass.get_format.to_s
      payload = build_payload(topic, klass, obj, opts)

      send_produce_request!(topic, payload, format)
    end

    private

    def build_payload(topic, klass, obj, opts)
      # TODO: oooh, dirty - this should not be here
      Payload.new(klass, obj, opts).build.tap do |pl|
        if kid = @key_schema_cache[topic]
          pl.delete :key_schema
          pl[:key_schema_id] = kid
        end

        if vid = @value_schema_cache[topic]
          pl.delete :value_schema
          pl[:value_schema_id] = vid
        end
      end
    end

    def send_produce_request!(topic, payload, format)
      @client.topic_produce_message(topic, payload, format).body.tap do |re|
        # this too (line 27)
        cache_schema_ids!(re, topic) if format == 'avro'
      end['offsets']
    end

    def cache_schema_ids!(resp, topic)
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
