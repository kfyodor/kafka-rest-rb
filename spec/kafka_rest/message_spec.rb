require 'base64'

describe KafkaRest::Message do
  context 'payload' do
    subject { message.send :build_payload }

    context 'json message' do
      let(:value) { { id: "id", name: "Test" } }
      let(:payload) { { key: "id", value: value } }

      context 'key as a proc' do
        class JsonMessage < KafkaRest::Message

          topic "test_topic"
          message_format :json
          key ->(obj){ obj[:id] }
        end

        let(:message) { JsonMessage.new(value) }

        it 'builds payload' do
          expect(subject).to eq payload
        end
      end

      context 'key as a method in a class' do
        class JsonMessageWithKeyAsAMethod < KafkaRest::Message
          topic "test_topic"
          message_format :json
          key :id

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
          topic 'test_topic'
          message_format :json
          key :object_key
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

    context 'binary message' do
      class BinaryMessage < KafkaRest::Message
        topic 'test_topic'
        message_format :binary
        key ->(obj) { obj[:id] }

        serializer(
          Class.new(KafkaRest::Message::Serializer) do
            def as_json
              Oj.dump @object
            end
          end
        )
      end

      let(:value) { { id: "id", test: 'test' } }
      let(:payload) do
        {
          key: "id",
          value: Base64.strict_encode64(Oj.dump value)
        }
      end

      let(:message) { BinaryMessage.new(value) }

      it 'builds payload' do
        expect(subject).to eq payload
      end
    end
  end
end
