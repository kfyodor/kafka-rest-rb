module KafkaRest
  class Config
    attr_accessor :url,
                  :message_format,
                  :serialization_adapter,
                  :worker_min_threads,
                  :worker_max_threads,
                  :worker_max_queue

    def initialize
      @url = 'http://localhost:8082'
      @message_format = 'json'
      @serialization_adapter = nil
      @worker_min_threads = 4
      @worker_max_threads = 4
      @worker_max_queue = nil
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
