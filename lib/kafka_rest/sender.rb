require 'thread'
require 'kafka_rest/sender/payload'

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
      topic, payload, format, params = build_request(klass, obj, opts)
      send_produce_request!(topic, payload, format, params)
    end

    private

    def build_request(klass, obj, opts)
      # TODO: oooh, dirty and weird - this should not be here.
      #       come up with something good!
      topic    = klass.get_topic.to_s
      payload  = Payload.new(klass, obj, opts).build
      format   = klass.get_format.to_s
      params   = {}.tap do |_p|
        if format == 'avro'
          if kid = @key_schema_cache[topic]
            _p[:key_schema_id] = kid
          else
            _p[:key_schema] = klass.get_key_schema
          end

          if vid = @value_schema_cache[topic]
            _p[:value_schema_id] = vid
          else
            _p[:value_schema] = klass.get_value_schema
          end
        end
      end

      [topic, payload, format, params]
    end

    def send_produce_request!(topic, payload, format, params)
      @client.topic_produce_message(topic, payload, format, params).body.tap do |re|
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
