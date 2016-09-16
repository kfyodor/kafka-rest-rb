module KafkaRest
  class Config
    attr_accessor :url,
                  :default_message_format,
                  :default_message_serializer

    def initialize
      @url = 'http://localhost:8082'
      @default_message_format = 'json'
      @default_message_serializer = nil
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
