require 'concurrent/utility/monotonic_time'

module KafkaRest
  class Worker
    class ConsumerManager
      STATES = [:initial, :idle, :working, :dead]

      include KafkaRest::Logging

      class << self
        @@consumers = []

        def register!(consumer_class)
          # TODO: raise exception if group_id + topic are not unique
          # TODO: Thread.current???
          @@consumers << consumer_class
        end

        def consumers
          @@consumers
        end
      end

      extend Forwardable

      def_delegators :@consumer,
                     :topic,
                     :group_name,
                     :poll_delay,
                     :auto_commit,
                     :offset_reset,
                     :format,
                     :max_bytes

      def initialize(client, consumer)
        @client    = client
        @consumer  = consumer.new
        @id        = nil
        @uri       = nil
        @state     = :initial
        @next_poll = Concurrent.monotonic_time
        @lock      = Mutex.new
      end

      STATES.each do |state|
        class_eval %Q{
          def #{state}?(lock = true)
            with_lock(lock) { @state == :#{state} }
          end
        }
      end

      def poll?
        with_lock {
          idle?(false) && Concurrent.monotonic_time > @next_poll
        }
      end

      def add!
        params = {}.tap do |h|
          auto_commit.nil? or h[:auto_commit_enable] = auto_commit
          offset_reset and h[:auto_offset_reset] = offset_reset
          format and h[:format] = format
        end

        resp   = @client.consumer_add(group_name, params)
        @id    = resp.body['instance_id']
        @uri   = resp.body['base_uri']
        @state = :idle

        logger.info "[Kafka REST] Added consumer #{@id}"
      end

      def remove!
        resp = @client.consumer_remove(group_name, @id)
        logger.info "[Kafka REST] Removed consumer #{@id}"
      end

      def poll!
        begin
          with_lock do
            return false unless idle?(false)
            @state = :working
          end

          logger.debug "Polling #{group_name}..."

          params = {}.tap do |h|
            format and h[:format] = format
            max_bytes and h[:max_bytes] = max_bytes
          end

          messages = @client.consumer_consume_from_topic(
            group_name,
            @id,
            topic,
            params
          ).body

          if messages.any?
            messages.each do |msg|
              logger.debug "[Kafka REST] Consumer #{@id} got message: #{msg}"
              @consumer.receive(msg)
            end

            unless auto_commit
              @client.consumer_commit_offsets(group_name, @id)
            end

            with_lock { @state = :idle }
          else
            with_lock do
              @next_poll = Concurrent.monotonic_time + poll_delay
              @state = :idle
            end
          end
        rescue Exception => e # TODO: handle errors
          logger.warn "[Kafka REST] Consumer died due to error: #{e.class}, #{e.message}"
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
