require 'spec_helper'

describe KafkaRest::Sender do
  class MockClient
    def topic_produce_message(topic, payload, format)
      :O_O
    end
  end


  def mock_client!
    ->(resp){
      allow_any_instance_of(MockClient)
        .to receive(:topic_produce_message).and_return(OpenStruct.new body: resp)
    }
  end

  subject { sender.send!(klass, obj) }

  let(:sender) { described_class.new(client) }
  let(:client) { MockClient.new }
  let(:obj) { "test" }
  let(:resp_without_schemas) do
    { 'offsets' => [{ partition: 0, offset: 100 }] }
  end

  let(:resp_with_schemas) do
    resp_without_schemas.merge('key_schema_id' => 10, 'value_schema_id' => 20)
  end

  let(:resp) { nil }

  context 'without schemas' do
    before(:each) do
      mock_client!.call(resp_without_schemas)
      expect(sender).not_to receive(:cache_schema_ids!)
    end

    context 'json' do
      let(:klass) { JsonProducer1 }
      it { should eq resp_without_schemas['offsets'] }
    end

    context 'binary' do
      let(:klass) { BinaryProducer1 }
      let(:obj) { SimpleObject.new("key", "value") }

      it { should eq resp_without_schemas['offsets'] }
    end
  end

  context 'with schemas' do
    before(:each) do
      mock_client!.call(resp_with_schemas)
    end

    let(:klass) { AvroProducer2 }

    it 'sends a message and caches schemas' do
      expect(subject).to eq resp_with_schemas['offsets']
      expect(sender.key_schema_cache).to eq({ 'test_topic' => 10 })
      expect(sender.value_schema_cache).to eq({ 'test_topic' => 20 })
    end

    it 'uses schema ids instead of schemas in payload if found' do
      subject

      params = sender.send(:build_request, klass, obj, {}).last

      expect(params).to have_key(:key_schema_id)
      expect(params).to have_key(:value_schema_id)
    end
  end
end
