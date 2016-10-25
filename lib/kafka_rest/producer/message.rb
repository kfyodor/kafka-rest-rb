module KafkaRest
  module Producer
    class Message
      attr_reader :topic, :payload, :format, :params

      def initialize(producer, obj, opts = {})
        @topic    = producer.get_topic.to_s
        @payload  = Payload.new(producer, obj, opts).build
        @format   = producer.get_format.to_s
        @params   = build_params(producer)
      end

      private

      # add schemas if format == 'avro'
      def build_params(producer)
        {}.tap do |params|
          if @format == 'avro'
            has_key = !producer.get_key.nil?
            params[:key_schema] = producer.get_key_schema if has_key
            params[:value_schema] = producer.get_value_schema
          end
        end
      end
    end
  end
end
