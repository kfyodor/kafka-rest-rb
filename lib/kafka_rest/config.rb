module KafkaRest
  class Config
    attr_accessor :url,
                  :message_format,
                  :serialization_adapter

    def initialize
      @url = 'http://localhost:8082'
      @message_format = 'json'
      @serialization_adapter = nil
    end
  end

  @@config = Config.new

  def self.configure(&block)
    block.call @@config
  end

  def self.config
    @@config
  end
end
