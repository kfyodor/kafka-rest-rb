module KafkaRest
  module Sender
    class KafkaSender

      @@instance = nil

      class << self
        def instance
          @@instance ||= self.new(Client.new)
        end

        def send!(message)
          instance.send!(message)
        end
      end

      attr_reader :key_schema_cache, :value_schema_cache

      def initialize(client, opts = {})
        @lock = Mutex.new
        @client = client
        @key_schema_cache = {}
        @value_schema_cache = {}
      end

      # TODO: back-off retry if offset[i].errors is a retriable error
      def send!(message)
        send_produce_request!(
          message.topic,
          message.payload,
          message.format,
          build_params(message)
        )
      end

      private

      # replace key and value schemas with
      # their ids if those are found in cache
      def build_params(message)
        return message.params unless message.format == 'avro'

        topic, params, format = message.topic, message.params, message.format

        {}.tap do |_p|
          if format == 'avro'
            if key_schema = params[:key_schema]
              if key_schema_id = @key_schema_cache[topic]
                _p[:key_schema_id] = key_schema_id
              else
                _p[:key_schema] = key_schema
              end
            end

            if value_schema_id = @value_schema_cache[topic]
              _p[:value_schema_id] = value_schema_id
            else
              _p[:value_schema] = params[:value_schema]
            end
          end
        end
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
end
