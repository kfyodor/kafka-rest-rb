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

    def topics
      request!(:get, "/topics")
    end

    def topic(topic)
      request!(:get, "/topics/#{topic}")
    end

    def topic_partitions(topic)
      request!(:get, "/topics/#{topic}/partitions")
    end

    def topic_partition(topic, partition)
      request!(:get, "/topics/#{topic}/partitions/#{partition}")
    end

    def topic_partition_messages(topic, partition, offset, count = 1)
      request!(
        :get,
        "/topics/#{topic}/partitions/#{partition}/messages",
        { offset: offset, count: count },
        headers: accept_header(:avro) # move this to config (and maybe we'll need per-topic format config)
      )
    end

    def topic_put_message(topic, message)
    end

    def consumer_add(group_name)
    end

    def consumer_commit_offsets(group_name, consumer_id)
    end

    def consumer_remove(group_name, consumer_id)
    end

    def consumer_consume_from_topic(group_name, consumer_id, topic)
    end

    def brokers
    end

    private

    def request!(method, path, params = {}, options = {})
      @conn.run_request(
        method.to_sym,
        path,
        params,
        options[:headers]
      ).body
    end

    def default_headers
      make_accept_header
    end

    def make_content_type_header(format = nil)

    def make_accept_header(format = nil)
      {
        #'Content-Type' => 'application/vnd.kafka.v1.avro+json',
        'Accept' => case format
                    when :avro
                      'application/vnd.kafka.avro.v1+json'
                    when :binary
                      'application/vnd.kafka.binary.v1+json'
                    else
                      'application/vnd.kafka.v1+json, application/vnd.kafka+json, application/json'
                    end
      }
    end
  end
end
