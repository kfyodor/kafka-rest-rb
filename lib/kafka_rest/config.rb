module KafkaRest
  class Config
    attr_accessor :url
    attr_accessor :default_message_format

    def initialize
      @url = 'http://localhost:8082'
      @default_message_format = 'json'
    end
  end

  @@config = Config.new
  cattr_accessor :config

  def self.configure &block
    block.call self.config
  end
end
