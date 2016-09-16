require 'kafka_rest/dsl'

module KafkaRest
  module Consumer
    def self.included(base)
      base.class_eval do
        extend Dsl

        option :topic, required: true

        option :group_name, required: true

        option :message_format, default: :json, validate: ->(val){
          %w(json binary avro).include?(val.to_s)
        }, error_message: 'Format must be either `json`, `avro` or `binary`'

        option :auto_commit, default: false

        option :offset_reset, default: :largest, validate: ->(val){
          %w(smallest largest).include?(val.to_s)
        }, error_message: 'Offset reset strategy must be `smallest` or `largest`'

        option :max_bytes

        option :poll_delay, default: 0.5, validate: ->(val){
          val > 0
        }, error_message: 'Poll delay should be a number greater than zero'
      end

      Worker::ConsumerManager.register!(base)
    end

    def receive(*args)
      raise NotImplementedError
    end
  end
end
