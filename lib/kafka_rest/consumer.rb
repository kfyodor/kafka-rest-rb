require 'kafka_rest/dsl'

module KafkaRest
  module Consumer
    def self.included(base)
      base.extend Dsl

      base.option :topic, required: true

      base.option :group_name, required: true

      base.option :message_format, default: :json, validate: ->(val){
        %w(json binary avro).include?(val.to_s)
      }, error_message: 'Format must be either `json`, `avro` or `binary`'

      base.option :auto_commit, default: false

      base.option :offset_reset, default: :largest, validate: ->(val){
        %w(smallest largest).include?(val.to_s)
      }, error_message: 'Offset reset strategy must be `smallest` or `largest`'

      base.option :max_bytes

      base.option :poll_delay, default: 0.5, validate: ->(val){
        val > 0
      }, error_message: 'Poll delay should be a number greater than zero'


      Worker::ConsumerManager.register!(base)
    end

    def receive(*args)
      raise NotImplemented
    end
  end
end
