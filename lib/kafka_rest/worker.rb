require 'kafka_rest/client'
require 'kafka_rest/worker/consumer_manager'
require 'kafka_rest/worker/error_handler'

require 'concurrent/executor/thread_pool_executor'

module KafkaRest
  class Worker
    BUSY_THREAD_POOL_DELAY = 0.5
    NO_WORK_DELAY = 0.1

    include KafkaRest::Logging

    def initialize(client)
      @client = client
      @started = false
      @util_threads = []
      @out_pipe, @in_pipe = IO.pipe
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
      trap('SIGINT') { @in_pipe.puts 'SIGINT' } # more signals

      begin
        @running = true

        util_thread { run_dead_cleaner }
        util_thread { run_work_loop }

        wait_for_signal
      rescue => e
        logger.error "[Kafka REST] Worker died due to an exception"
        ErrorHandler.handle_error(e)
        stop
      ensure
        [@in_pipe, @out_pipe].each &:close
      end
    end

    def stop
      logger.info "[Kafka REST] Stopping worker..."

      @running = false
      @util_threads.map &:join

      logger.info "[Kafka REST] Bye."
      exit(0)
    end

    private

    # a dirty hack
    def send_quit
      @in_pipe.puts "SIGINT"
    end

    def wait_for_signal
      while data = IO.select([@out_pipe])
        signal = data.first[0].gets.strip
        handle_signal(signal)
      end
    end

    def handle_signal(signal)
      case signal
      when 'SIGINT'
        stop
      else
        raise Interrupt
      end
    end

    # Runs some job in an utility thread
    def util_thread(&block)
      parent = Thread.current

      @util_threads << Thread.new(&block).tap do |t|
        t.abort_on_exception = true
      end
    end

    def run_dead_cleaner
      while @running
        sleep(3)

        dead     = @consumers.select(&:dead?)
        all_dead = @consumers.count == dead.count

        dead.each(&:remove!)

        if all_dead
          logger.warn "All consumers are dead."
          send_quit if KafkaRest.config.shutdown_when_all_dead
        end
      end
    end

    def run_work_loop
      init_consumers

      while @running
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

      remove_consumers
    end

    def init_consumers
      @consumers.select(&:initial?).each(&:add!)
    end

    def remove_consumers
      @consumers.reject(&:initial?).each(&:remove!)
    end

    def max_queue
      KafkaRest.config.worker_max_queue ||
        ConsumerManager.consumers.size * 2
    end
  end
end
