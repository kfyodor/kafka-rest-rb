class AvroProducer1
  include KafkaRest::Producer

  topic :test_topic
  format :avro
  value_schema "string"
end

class JsonProducer1
  include KafkaRest::Producer

  topic :test_topic
  format :json
  key :get_key

  def get_key(obj)
    "got_key: #{obj}"
  end
end

class SimpleSerializer < KafkaRest::Producer::Serialization::Adapter
  def serialize(obj, opts = {})
    obj.value.to_s
  end
end

SimpleObject = Struct.new(:get_key, :value)

class BinaryProducer1
  include KafkaRest::Producer

  topic :test_topic
  format :binary
  serialization_adapter SimpleSerializer
  key :get_key # expects an object with method get_key
end
