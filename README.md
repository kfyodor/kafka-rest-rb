# Kafka-REST client, producer/consumer DSLs and worker daemon for Ruby/Rails apps. 
[![Gem Version](https://badge.fury.io/rb/kafka-rest-rb.svg)](https://badge.fury.io/rb/kafka-rest-rb) [![CircleCI](https://circleci.com/gh/konukhov/kafka-rest-rb.svg?style=shield)](https://circleci.com/gh/konukhov/kafka-rest-rb)

Note: *This project is in early development stage.*

This project is aimed to bring [Confluent Platform](http://docs.confluent.io/3.0.1/)'s services, such as Kafka and Schema Registry, to Ruby world (MRI of course, since there's no problem using Java libraries from JRuby). Confluent has done a great job bringing us [Kafka REST proxy](http://docs.confluent.io/3.0.1/kafka-rest/docs/index.html), a project that helps working with Kafka consumers and producers from any non-JVM platform through REST API, but still: setting it up and using it correctly is not a trivial task. Hopefully, with `kafka-rest-rb` working with Kafka will be as easy as working with Sidekiq, Hutch or Resque.

`Kafka-rest-rb` consists of 4 main parts:
+ **Consumer and Producer DSLs**: DSLs for defining consumers and producers within your app
+ **Producer**: producing and sending messages.
+ **Client**: Kafka REST proxy API client.
+ **Worker**: a separate process that consumes and processes messages from Kafka REST proxy.

## Installation

### 1. Confluent Platform

First, you need to get Zookeeper, Kafka, Kafka REST and Schema Registry (only if you want AVRO-serializing), all of which are included in Confluent Platform, which can be downloaded [here](https://www.confluent.io/download).

Note, that theses inctructions are for development environments only. For production deployments refer to Confluent's documentation.

Then, start all services mentioned above in order:

```bash
cd confluent-platform-dir
./bin/zookeeper-server-start etc/kafka/zookeeper.properties
./bin/kafka-server-start etc/kafka/server.properties
./bin/schema-registry-start etc/schema-registry.properties # if you need AVRO serialization
./bin/kafka-rest-start etc/kafka-rest/kafka-rest.properties

```

You might want to create some topics:

```
kafka-topics --zookeeper :2181 --create --topic my_topic --replication-factor 1 --partitions 1
```

Or just set `auto.create.topics.enable` to true in kafka/server.properties.

### 2. Ruby gem

Run

```bash
gem install kafka-rest-rb -v 0.1.0.alpha6
```

Or just add this to your `Gemfile`:

```ruby
gem 'kafka-rest', '0.1.0.alpha6'
```

## Usage

Before using `kafka-rest-rb` you might want to get familiar with some Kafka concepts, such as topics, partitions, offsets, keys, consumer groups etc. You can read about it [here](http://kafka.apache.org/intro).

### DSLs

#### Producer

Include `KafkaRest::Producer` module to some class in order to make a producer.

##### Available methods:

| name | type | required | default | description
| --- | --- | --- | --- | --- |
| **topic** | _String_ | yes | | A Kafka topic name messages will be sent to.
| **format** | _Enum(`json`, `binary`, `avro`)_ | yes | `json` | A message format. Kafka REST can accept messages in JSON, AVRO or binary formats. |
| **key** | _Symbol_ or _Proc_ | no | | A method name or proc which returns a message key. It could be a method implemented in producer's class, a method on provided object or a proc which takes provided object as an argument. See details in [Producer's documentation](#todo).
| **serialization_adapter** | _Class_ | no | | Serializer class
| **serializer** | _Any_ | no | | Additional arguments for serializer. Read about serializers [below](#todo)
| **key_schema** | _String_ | no | `"{\"type\": \"string\"}"` when key is not empty | AVRO schema (a JSON-encoded string) for encoding keys
| **value_schema** | _String_ | yes if format is `avro` | |  AVRO schema for encoding values.

##### Example

```ruby
class MyProducer
  include KafkaRest::Producer
  
  topic :clicks
  format :json
  key :user_id
end
```

#### Consumer

Include `KafkaRest::Consumer` module to some class in order to make a consumer from that class. Also, you must implement `receive(msg)` in consumer class to be able to process messages.

##### Available methods:

| name | type | required | default | description
| --- | --- | --- | --- | --- |
| **topic** | _String_ | yes | | A topic messages will be consumed from.
| **group_name** | _String_ | yes | | Consumer group name. Kafka will be load balancing messages between consumers from same group subscribed to same topic.
| **format** | _Enum(`json`, `binary`, `avro`)_ | yes | `json` | A message format. Kafka REST can receive messages in JSON, AVRO or binary formats.
| **auto_commit** | _Boolean_ | no | `false` | Auto commit is not recommended for most cases because it weakens message delivery guarantees.
| **offset_reset** | _Enum(`smallest`, `largest`)_ | no | `largest` | Consumer offset reset strategy when a new consumer group subscribes to a topic. Basically it means from which offset new consumer will be reading messages: if smallest, consumer will get all messages from the beginning of topic as well; if largest, consumer will be getting only new messages.
| **max_bytes** | _Long_ | no | | Kafka Consumer receives messages in batches. This option specifies a maximum batch size in bytes.
| **poll_delay** | _Long_ | no | `0.5` | A number of seconds between consumer poll requests. 

##### Example:

```ruby
class MyConsumer
  include KafkaRest::Consumer
  
  topic :clicks
  format :json
  
  def receive(msg)
	Click.create(user_id: msg.value['user_id'], url: msg.value['url'])
  end
end
```

_More on the way..._
