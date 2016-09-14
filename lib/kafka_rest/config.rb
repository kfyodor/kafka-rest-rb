module KafkaRest
  class Config
    attr_accessor :url,
                  :default_message_format

    def initialize
      @url = 'http://localhost:8082'
      @default_message_format = 'json'
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
