require 'kafka_rest/client'
require 'kafka_rest/worker/consumer_manager'
require 'concurrent/executor/thread_pool_executor'

module KafkaRest
  class Worker
    def initialize(client)
      @client = client
      @started = false
      @producer = nil
      @thread_pool = Concurrent::ThreadPoolExecutor.new(
        min_threads: 4, # find the right number
        max_threads: 4,
        max_queue: ConsumerManager.consumers.size * 2,
        fallback_policy: :discard
      )

      @consumers = ConsumerManager.consumers.map do |kl|
        ConsumerManager.new(@client, kl)
      end
    end

    def start
      begin
        @running = true

        trap(:SIGINT) do
          puts "[Kafka REST] Stopping work loop..."
          stop
        end

        init_consumers
        run_work_loop
      rescue => e
        puts "[Kafka REST] Got exception: #{e.class} (#{e.message})"

        e.backtrace.each do |msg|
          puts "\t #{msg}"
        end

        puts "[Kafka REST] Stopping..."
        stop
      end
    end

    def stop
      @producer.kill if @producer
      @running = false
      remove_consumers
    end

    private

    def run_work_loop
      while @running
        check_dead!

        # Temporary.
        @consumers.select(&:idle?).each do |c|
          sleep(1) unless @thread_pool.post do
            sleep(1) unless c.poll!
          end
        end
      end
    end

    def check_dead!
      if @consumers.all?(&:dead?)
        puts "[Kafka REST] All consumers are dead. Quitting..."
        stop
      end
    end

    def init_consumers
      @consumers.map &:add!
    end

    def remove_consumers
      @consumers.reject(&:initial?).map &:remove!
    end
  end
end
