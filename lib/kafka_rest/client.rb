require 'faraday'
require 'client/middleware.rb'

module KafkaRest
  class Client
    def initialize
      @conn = Faraday.new(url: 'http://localhost:8082') do |c|
        c.request :json
        c.request :log_resp
        c.request :default_headers, default_headers

        c.response :raise_exception
        c.response :json

        c.adapter :net_http_persistent
      end
    end

    # Get list of topics
    ### returns: array of topics
    def topics
      @conn.get("/topics")
    end

    # Get topic metadata by name
    ### returns: name, configs, partitions
    def topic(topic)
      @conn.get("/topics/#{topic}")
    end

    # Get topic's partitions
    ###
    def topic_partitions(topic)
      @conn.get("/topics/#{topic}/partitions")
    end

    # Get topic's partition metadata
    def topic_partition(topic, partition)
      @conn.get("/topics/#{topic}/partitions/#{partition}")
    end

    # Get messages from topic's partition.
    def topic_partition_messages(topic, partition, params = {})
      params[:count] ||= 1
      format = params.delete(:format) || 'binary'

      @conn.get(
        "/topics/#{topic}/partitions/#{partition}/messages",
        params,
        accept(format)
      )
    end

    def produce_message(path, records, format)
      body = { records: records.is_a?(Array) ? records : [records] }
      @conn.post(path, body, content_type(format))
    end
    private :produce_message

    # Produce message into a topic
    ### params: key_schema, value_schema, key_schema_id, value_schema_id, records { key, value, partition }
    ### returns: key_schema_id, value_schema_id, offsets { partition, offset, error_code, error }
    def topic_produce_message(topic, records, format = 'json')
      produce_message("topics/#{topic}", records, format)
    end

    # Produce message into a topic and partition
    ### see topic_produce_message
    def topic_partition_produce_message(topic, partition, records, format = 'json')
      produce_message("topics/#{topic}/partitions/#{partition}", records, format)
    end

    # Add new consumer to a group
    ### params: name, format, auto.offset.reset, auto.commit.enable
    ### returns: instance_id, base_uri
    def consumer_add(group_name, params = {})
      body = {}
      body['auto.offset.reset'] = params[:auth_offset_reset] || 'largest'
      body['auto.commit.enable'] = params[:auto_commit_enable] == true || false
      body['format'] = params[:format] || 'json'

      @conn.post("consumers/#{group_name}", body)
    end

    def consumer_commit_offsets(group_name, consumer_id)
      @conn.post("consumers/#{group_name}/instances/#{consumer_id}/offsets")
    end

    def consumer_remove(group_name, consumer_id)
      @conn.delete("consumers/#{group_name}/instances/#{consumer_id}")
    end

    def consumer_consume_from_topic(group_name, consumer_id, topic, params = {})
      format = params.delete(:format) || 'json'

      @conn.get(
        "consumers/#{group_name}/instances/#{consumer_id}/topics/#{topic}",
        params,
        accept(format)
      )
    end

    def brokers
      @conn.get("/brokers")
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
