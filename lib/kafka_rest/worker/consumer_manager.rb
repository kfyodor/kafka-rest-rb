require 'concurrent/utility/monotonic_time'
require 'kafka_rest/worker/consumer_message'
require 'kafka_rest/worker/consumer'

module KafkaRest
  class Worker
    class ConsumerManager
      # Manages state and lifecycle of a Consumer instance

      STATES = [:initial, :idle, :working, :dead]

      include KafkaRest::Logging

      class << self
        @@register_consumer_procs = []
        @@consumers = nil

        def register!(consumer)
          # Delay consumers validating until they are actually needed
          # and all classes are loaded.
          @@register_consumer_procs << ->(consumers){
            topic, group_name = consumer.get_topic, consumer.get_group_name

            if topic.nil?
              raise Exception.new("#{consumer.name}: topic must not be empty")
            end

            if group_name.nil?
              raise Exception.new("#{consumer.name}: group_name must not be empty")
            end

            key = [topic, group_name]

            if consumers.has_key?(key)
              raise Exception.new("#{consumer.name}: group_name and topic are not unique")
            end

            { key => consumer }
          }
        end

        def consumers
          @@consumers ||= @@register_consumer_procs.reduce({}) do |c, p|
            c.merge(p.call c)
          end.values
        end
      end

      def initialize(client, klass)
        @consumer   = Consumer.new(klass, client)
        @state      = :initial
        @poll_delay = klass.get_poll_delay
        @next_poll  = Concurrent.monotonic_time
        @lock       = Mutex.new
      end

      STATES.each do |state|
        class_eval %Q{
          def #{state}?(lock = true)
            with_lock(lock) { @state == :#{state} }
          end
        }
      end

      def poll?(lock = true)
        with_lock(lock) do
          idle?(false) && Concurrent.monotonic_time > @next_poll
        end
      end

      def add!
        with_lock do
          return nil if @consumer.added?
          @consumer.add!
          @state = :idle
        end
      end

      def remove!
        with_lock do
          return nil unless @consumer.added?
          @consumer.remove!
          @state = :initial
        end
      end

      def poll!
        with_lock do
          return nil unless idle?(false)
          @state = :working
        end

        begin
          unless @consumer.poll!
            @next_poll = Concurrent.monotonic_time + @poll_delay
          end

          with_lock { @state = :idle }
        rescue Exception => e
          # TODO:
          # - Recover from Faraday errors.
          # - Mark dead only when encountering application errors,
          #   because it's obvious that after restart it will be raised again
          logger.error "[Kafka REST] Consumer died due to an error"
          ErrorHandler.handle_error(e)

          with_lock { @state = :dead }
        end
      end

      private

      def with_lock(lock = true, &block)
        if lock
          @lock.synchronize &block
        else
          block.call
        end
      end
    end
  end
end
