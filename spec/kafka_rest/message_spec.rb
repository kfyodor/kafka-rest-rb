require 'base64'

describe KafkaRest::Message do
  context 'payload' do
    subject { message.send :build_payload }

    module NoopSerializer
      def noop_serializer
        Class.new(KafkaRest::Message::SerializationAdapter) do
          def serialize
            @obj
          end
        end
      end
    end

    context 'json message' do
      let(:value) { { id: "id", name: "Test" } }
      let(:payload) { { key: "id", value: value, topic: "test_topic" } }

      context 'key as a proc' do
        class JsonMessage < KafkaRest::Message
          extend NoopSerializer

          topic "test_topic"
          message_format :json
          key ->(obj){ obj[:id] }
          serializer noop_serializer
        end

        let(:message) { JsonMessage.new(value) }

        it 'builds payload' do
          expect(subject).to eq payload
        end
      end

      context 'key as a method in a class' do
        class JsonMessageWithKeyAsAMethod < KafkaRest::Message
          extend NoopSerializer

          topic "test_topic"
          message_format :json
          key :id
          serializer noop_serializer

          def id
            object[:id]
          end
        end

        let(:message) { JsonMessageWithKeyAsAMethod.new(value) }

        it 'builds payload' do
          expect(subject).to eq payload
        end
      end

      context 'key as an objec\'s method' do
        class JsonMessageWithKeyAsAnInstanceMethod < KafkaRest::Message
          extend NoopSerializer

          topic 'test_topic'
          message_format :json
          key :object_key
          serializer noop_serializer
        end

        let(:message) {
          value.instance_eval { def object_key; "id"; end }
          JsonMessageWithKeyAsAnInstanceMethod.new(value)
        }

        it 'builds payload' do
          expect(subject).to eq payload
        end
      end
    end

    context 'avro message' do
      let(:value) { { id: "id", test: 'test' } }
      let(:payload) do
        {
          key: "id",
          value: Base64.strict_encode64(Oj.dump value),
          topic: "test_topic"
        }
      end

      let(:message) do
        Class.new(KafkaRest::Message) do
          def self._serializer
            Class.new(KafkaRest::Message::SerializationAdapter) do
              def serialize
                Oj.dump @obj
              end
            end
          end

          topic 'test_topic'
          message_format :binary
          key ->(obj) { obj[:id] }
          serializer _serializer
        end.new(value)
      end

      it 'builds payload' do
        expect(subject).to eq payload
      end
    end
  end
end
