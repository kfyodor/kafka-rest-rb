require 'spec_helper'

describe KafkaRest::Producer do
  let(:klass) { JsonProducer1 }

  context 'attrs' do
    subject { klass }

    it 'has topic' do
      expect(subject.get_topic).to eq :test_topic
    end

    it 'has format' do
      expect(subject.get_format).to eq :json
    end

    it 'has_key fn' do
      expect(subject.get_key).to eq :get_key
    end

    it 'sends a message' do
      obj = "test"
      expect(KafkaRest::Sender.instance)
        .to receive(:send!).with(klass, obj, {})

      klass.send!(obj)
    end
  end
end
