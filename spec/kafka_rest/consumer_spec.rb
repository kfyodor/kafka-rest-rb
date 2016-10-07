require 'spec_helper'

describe KafkaRest::Consumer do
  class TestConsumer
    include KafkaRest::Consumer

    topic "stuff"
    group_name "test_consumer"
    format :json
    auto_commit false
    offset_reset :smallest
    poll_delay 0.2
  end

  it 'has been registered in worker' do
    expect(KafkaRest::Worker::ConsumerManager.consumers).to eq [TestConsumer]
  end

  it 'has topic' do
    expect(TestConsumer.get_topic).to eq "stuff"
  end

  it 'has group name' do
    expect(TestConsumer.get_group_name).to eq "test_consumer"
  end

  it 'has message format' do
    expect(TestConsumer.get_format).to eq :json
  end

  it 'has auto_commit' do
    expect(TestConsumer.get_auto_commit).to eq false
  end

  it 'has offset_reset' do
    expect(TestConsumer.get_offset_reset).to eq :smallest
  end

  it 'has poll_delay' do
    expect(TestConsumer.get_poll_delay).to eq 0.2
  end
end
