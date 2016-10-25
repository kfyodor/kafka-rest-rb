require 'spec_helper'

describe KafkaRest::Producer::Payload do
  let(:obj) { "test" }
  let(:payload) { described_class.new(klass, obj) }

  context '#key' do
    subject { payload.key }

    context 'key is nil' do
      let(:klass) { AvroProducer1 }
      it { should be_nil }
    end

    context 'key is a method on a producer class' do
      let(:klass) { JsonProducer1 }
      it { should eq "got_key: test" }
    end

    context 'keys is a method on an object' do
      let(:klass) { BinaryProducer1 }
      let(:obj) { SimpleObject.new("key", "value") }

      it { should eq "key" }
    end
  end

  context '#value' do
    subject { payload.value }

    let(:klass) { BinaryProducer1 }
    let(:obj) { SimpleObject.new("key", "value") }

    it { should eq "value" }
  end

  context '#build' do
    subject { payload.build }

    context 'avro' do
      let(:klass) { AvroProducer1 }

      it do
        should eq({
          key: nil,
          value: "test"
        })
      end
    end

    context 'binary' do
      let(:klass) { BinaryProducer1 }
      let(:obj) { SimpleObject.new("1", "2") }

      it do
        should eq({
          key: "1",
          value: Base64.strict_encode64("2")
        })
      end
    end

    context 'json' do
      let(:klass) { JsonProducer1 }

      it do
        should eq({
          key: "got_key: test",
          value: "test"
        })
      end
    end
  end
end
