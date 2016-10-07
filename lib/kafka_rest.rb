require 'kafka_rest/config'
require 'kafka_rest/worker'
require 'kafka_rest/client'
require 'kafka_rest/producer'
require 'kafka_rest/producer/serialization/adapter'
require 'kafka_rest/sender'
require 'kafka_rest/sender/payload'
require 'kafka_rest/message'
require 'kafka_rest/consumer'

KafkaRest.configure do |c|
  serializers = KafkaRest::Producer::Serialization

  if defined?(ActiveModelSerializers) || defined?(ActiveModel::Serializer)
    require 'kafka_rest/producer/serialization/active_model'
    c.serialization_adapter = serializers::ActiveModel
  # elsif defined?(JBuilder)
  # TODO jbuilder is default
  # elsif defined?(Rabl)
  # TODO rabl is default
  else
    require 'kafka_rest/producer/serialization/noop'
    c.serialization_adapter = serializers::Noop
  end
end
