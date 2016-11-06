module KafkaRest
  class Config
    attr_accessor :url,
                  :message_format,
                  :serialization_adapter,
                  :worker_min_threads,
                  :worker_max_threads,
                  :worker_max_queue,
                  :shutdown_when_all_dead

    attr_reader :sender,
                :worker_error_handlers

    def initialize
      @url = 'http://localhost:8082'
      @message_format = 'json'
      @serialization_adapter = nil
      @worker_min_threads = 4
      @worker_max_threads = 4
      @worker_max_queue = nil
      @worker_error_handlers = []
      @shutdown_when_all_dead = false
      @sender = KafkaRest::Sender::KafkaSender
    end

    def sender=(_sender)
      if KafkaRest::Sender.valid?(_sender)
        @sender = _sender
      else
        raise InvalidConfigValue.new("sender", _sender, "Sender be a child of `KafkaRest::Sender`")
      end
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
