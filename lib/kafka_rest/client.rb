require 'faraday'
require 'faraday_middleware'

module KafkaRest
  class Client

    def initialize
      @conn = Faraday.new(url: 'http://localhost:8082') do |c|
        # c.use :instrumentation#  if config.instrumentation

        c.request :json
        c.response :json

        c.adapter :net_http_persistent
      end
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
    def topic_partition_messages(topic, partition, offset, count = 1)
      params = { offset: offset, count: count }
      opts =   { headers: accept_header(:avro) } # move this to config (and maybe we'll need per-topic format config)

      get("/topics/#{topic}/partitions/#{partition}/messages", params, opts)
    end

    # Produce message into a topic
    ### params: key_schema, value_schema, key_schema_id, value_schema_id, records { key, value, partition }
    ### returns: key_schema_id, value_schema_id, offsets { partition, offset, error_code, error }
    def topic_produce_message(topic, message)
      opts = { headers: accept_header.merge(content_type_header(:avro)) }
      post("topics/#{topic}", message, opts)
    end

    # Produce message into a topic and partition
    ### see topic_produce_message
    def topic_partition_produce_message(topic, partition, message)
      opts = { headers: accept_header.merge(content_type_header(:avro)) }
      post("topics/#{topic}/partitions/#{partition}", message, opts)
    end

    # Add new consumer to a group
    ### params: name, format, auto.offset.reset, auto.commit.enable
    ### returns: instance_id, base_uri
    def consumer_add(group_name, params)
      post("consumers/#{group_name}", params, headers: accept_header)
    end

    def consumer_commit_offsets(group_name, consumer_id)
      post("consumers/#{group_name}/instances/#{consumer_id}/offsets", nil, headers: accept_header)
    end

    def consumer_remove(group_name, consumer_id)
      delete("consumers/#{group_name}/instances/#{consumer_id}", headers: accept_header)
    end

    def consumer_consume_from_topic(group_name, consumer_id, topic, params = {})
      get(
        "consumers/#{group_name}/instances/#{consumer_id}/topics/#{topic}",
        params,
        headers: accept_header(:avro))
    end

    def brokers
      get("/brokers")
    end

    private

    def request!(method, path, params, options)
      @conn.run_request(
        method.to_sym,
        path,
        params,
        options[:headers]
      ).body # TODO: error handling
    end

    def get(path, params = {}, opts = {})
      request!(:get, path, params, opts)
    end

    def post(path, params = {}, opts = {})
      request!(:post, path, params, opts)
    end

    def delete(path, opts = {})
      request!(:delete, path, nil, opts)
    end

    def default_headers
      accept_header
    end

    def mime_type(format = :json)
      case format
      when :avro
        'application/vnd.kafka.avro.v1+json'
      when :binary
        'application/vnd.kafka.binary.v1+json'
      when :json
        'application/vnd.kafka.v1+json'
      end
    end

    def accept_header(format = nil)
      { 'Accept' => mime_type(format) }
    end

    def content_type_header(format = nil)
      { 'Content-Type' => mime_type(format) }
    end
  end
end
