require 'kafka_rest/client/middleware.rb'
require 'faraday'
require 'connection_pool'

module KafkaRest
  class Client
    def initialize
      @conn = ConnectionPool.new(size: 8, timeout: 5) do
        Faraday.new(url: KafkaRest.config.url) do |c|
          c.request :encode_json
          c.request :default_headers, default_headers

          c.response :raise_exception
          c.response :decode_json

          c.adapter :net_http_persistent
        end
      end
    end

    %w(get post put delete).each do |m|
      class_eval %Q{
        def #{m}(*args)
          @conn.with do |c|
            c.#{m}(*args)
          end
        end
      }
    end

    # Get list of topics
    ### returns: array of topics
    def topics
      get("/topics")
    end

    # Get topic metadata by name
    ### returns: name, configs, partitions
    def topic(topic)
      get("/topics/#{topic}")
    end

    # Get topic's partitions
    ###
    def topic_partitions(topic)
      get("/topics/#{topic}/partitions")
    end

    # Get topic's partition metadata
    def topic_partition(topic, partition)
      get("/topics/#{topic}/partitions/#{partition}")
    end

    # Get messages from topic's partition.
    def topic_partition_messages(topic, partition, params = {})
      params[:count] ||= 1
      format = params.delete(:format) || 'binary'

      get(
        "/topics/#{topic}/partitions/#{partition}/messages",
        params,
        accept(format)
      )
    end

    def produce_message(path, records, format, params)
      body = params.merge(
        records: records.is_a?(Array) ? records : [records]
      )

      post(path, body, content_type(format))
    end
    private :produce_message

    # Produce message into a topic
    ### params: key_schema, value_schema, key_schema_id, value_schema_id, records { key, value, partition }
    ### returns: key_schema_id, value_schema_id, offsets { partition, offset, error_code, error }
    def topic_produce_message(topic, records, format = 'json', params = {})
      produce_message("topics/#{topic}", records, format, params)
    end

    # Produce message into a topic and partition
    ### see topic_produce_message
    def topic_partition_produce_message(topic, partition, records, format = 'json', params = {})
      produce_message("topics/#{topic}/partitions/#{partition}", records, format, params)
    end

    # Add new consumer to a group
    ### params: name, format, auto.offset.reset, auto.commit.enable
    ### returns: instance_id, base_uri
    def consumer_add(group_name, params = {})
      body = {}
      body['auto.offset.reset'] = params[:auth_offset_reset] || 'largest'
      body['auto.commit.enable'] = params[:auto_commit_enable] == true || false
      body['format'] = params[:format] || 'json'

      post("consumers/#{group_name}", body)
    end

    def consumer_commit_offsets(group_name, consumer_id)
      post("consumers/#{group_name}/instances/#{consumer_id}/offsets")
    end

    def consumer_remove(group_name, consumer_id)
      delete("consumers/#{group_name}/instances/#{consumer_id}")
    end

    def consumer_consume_from_topic(group_name, consumer_id, topic, params = {})
      format = params.delete(:format) || 'json'

      get(
        "consumers/#{group_name}/instances/#{consumer_id}/topics/#{topic}",
        params,
        accept(format)
      )
    end

    def brokers
      get("/brokers")
    end

    private

    def default_headers
      {
        'Accept' => 'application/vnd.kafka.v1+json, application/vnd.kafka+json, application/json',
        'Content-Type' => 'application/vnd.kafka.v1+json'
      }
    end

    def kafka_mime_type(format = :json)
      case format.to_sym
      when :avro
        'application/vnd.kafka.avro.v1+json'
      when :binary
        'application/vnd.kafka.binary.v1+json'
      when :json
        'application/vnd.kafka.json.v1+json'
      end
    end

    def content_type(format = nil, headers = {})
      headers.merge 'Content-Type' => kafka_mime_type(format)
    end

    def accept(format, headers = {})
      headers.merge 'Accept' => kafka_mime_type(format)
    end
  end
end
