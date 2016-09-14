require 'concurrent/utility/monotonic_time'

module KafkaRest
  class Worker
    class ConsumerManager
      STATES = [:initial, :idle, :working, :dead]
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

      def_delegators :@consumer, :_topic, :_group_name, :_poll_delay

      def initialize(client, consumer)
        @client    = client
        @consumer  = consumer
        @instance  = consumer.new
        @id        = nil
        @uri       = nil
        @state     = :initial
        @next_poll = Concurrent.monotinic_time
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
          idle?(false) && Concurrent.monotinic_time > @next_poll
        }
      end

      def add!
        params = {}.tap do |h|
          @consumer._auto_commit.nil? or
            h[:auto_commit_enable] = @consumer._auto_commit

          @consumer._offset_reset and
            h[:auto_offset_reset] = @consumer._offset_reset

          @consumer._message_format and
            h[:format] = @consumer._message_format
        end

        resp   = @client.consumer_add(_group_name, params)
        @id    = resp.body['instance_id']
        @uri   = resp.body['base_uri']
        @state = :idle
        puts "[Kafka REST] Added consumer #{@id}"
      end

      def remove!
        resp = @client.consumer_remove(_group_name, @id)
        puts "[Kafka REST] Removed consumer #{@id}"
      end

      def poll!
        begin
          with_lock do
            return false unless idle?(false)
            @state = :working
          end

          params = {}.tap do |h|
            @consumer._message_format and
              h[:format] = @consumer._message_format

            @consumer._max_bytes and
              h[:max_bytes] = @consumer._max_bytes
          end

          messages = @client.consumer_consume_from_topic(
            _group_name,
            @id,
            _topic,
            params
          ).body

          if messages.any?
            messages.each do |msg|
              puts "[Kafka REST] Consumer #{@id} got message: #{msg}"
              @instance.receive(msg)
            end
            @client.consumer_commit_offsets(_group_name, @id)
          else
            with_lock {
              @next_poll = Concurrent.monotonic_time + _poll_delay
            }
          end

          with_lock { @state = :idle }
        rescue Exception => e # TODO: handle errors
          puts "[Kafka REST] Consumer died due to error: #{e.class}, #{e.message}"
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
