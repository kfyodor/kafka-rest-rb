require 'kafka_rest/config'
require 'kafka_rest/worker'
require 'kafka_rest/client'
require 'kafka_rest/producer'
require 'kafka_rest/message'
require 'kafka_rest/consumer'

KafkaRest.configure do |c|
  if defined?(ActiveModelSerializers)
    require 'kafka_rest/message/serializers/active_model'
    c.default_message_serializer = KafkaRest::Message::Serializers::ActiveModel
  # elsif defined?(JBuilder)
  # TODO jbuilder is default
  # elsif defined?(Rabl)
  # TODO rabl is default
  else
    require 'kafka_rest/message/serializers/noop'
    c.default_message_serializer = KafkaRest::Message::Serializers::Noop
  end
end
