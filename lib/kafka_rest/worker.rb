require 'kafka_rest/client'
require 'kafka_rest/worker/consumer_manager'
require 'concurrent/executor/thread_pool_executor'

module KafkaRest
  class Worker
    BUSY_THREAD_POOL_DELAY = 0.5
    NO_WORK_DELAY = 0.1

    include KafkaRest::Logging

    def initialize(client)
      @client = client
      @started = false
      @thread_pool = Concurrent::ThreadPoolExecutor.new(
        min_threads: KafkaRest.config.worker_min_threads,
        max_threads: KafkaRest.config.worker_max_threads,
        max_queue:   max_queue,
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
          stop
        end

        init_consumers
        run_work_loop
      rescue => e
        logger.error "[Kafka REST] Got exception: #{e.class} (#{e.message})"
        e.backtrace.each { |msg| logger.error "\t #{msg}" }
        stop
      end
    end

    def stop
      logger.info "[Kafka REST] Stopping worker..."
      @running = false
      remove_consumers
    end

    private

    def run_work_loop
      while @running
        check_dead!

        jobs = @consumers.select(&:poll?)

        if jobs.empty?
          sleep(NO_WORK_DELAY)
          next
        end

        pool_available = jobs.each do |c|
          unless @thread_pool.post { c.poll! }
            break(false)
          end
        end

        unless pool_available
          sleep(BUSY_THREAD_POOL_DELAY)
        end
      end
    end

    def check_dead!
      # Do we need this?
      if @consumers.all?(&:dead?)
        logger.info "[Kafka REST] All consumers are dead. Quitting..."
        stop
      end
    end

    def init_consumers
      @consumers.map &:add!
    end

    def remove_consumers
      @consumers.reject(&:initial?).map &:remove!
    end

    def max_queue
      KafkaRest.config.worker_max_queue ||
        ConsumerManager.consumers.size * 2
    end
  end
end
