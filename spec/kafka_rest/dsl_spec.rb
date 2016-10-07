require 'kafka_rest/dsl'

describe KafkaRest::Dsl do
  class TestDsl
    extend KafkaRest::Dsl

    option :simple_option
    option :option_with_default, default: 1
    option :option_with_validation, validate: ->(val) { val == 1 }
    option :option_with_validation_and_err_msg,
           validate: -> (val) { val == 1 },
           error_message: "Should eq 1"
    option :option_with_required, required: true
  end

  subject { TestDsl }

  it 'defines methods and vars' do
    [
      :simple_option,
      :option_with_default,
      :option_with_validation,
      :option_with_validation_and_err_msg,
      :option_with_required
    ].each do |m|
      expect(subject).to respond_to("#{m}")
      expect(subject).to respond_to("get_#{m}")
      expect(subject.new).to respond_to("#{m}")
    end
  end

  context 'simple option' do
    it 'has default value of nil' do
      expect(subject.get_simple_option).to be_nil
    end

    it 'sets option' do
      subject.simple_option 1
      expect(subject.get_simple_option).to eq 1
      expect(subject.new.simple_option).to eq 1
    end
  end

  context 'option with default' do
    it 'has default value' do
      expect(subject.get_option_with_default).to eq 1
    end

    it 'sets value' do
      subject.option_with_default 2
      expect(subject.get_option_with_default).to eq 2
    end
  end

  context 'option with validation' do
    it 'raises an error if invalid' do
      expect {
        subject.option_with_validation 2
      }.to raise_error(KafkaRest::Dsl::InvalidOptionValue, '`option_with_validation`\'s value is invalid')

    end

    it 'doenst raise an error if valid' do
      expect {
        subject.option_with_validation 1
      }.not_to raise_error
      expect(subject.get_option_with_validation).to eq 1
    end
  end
end
