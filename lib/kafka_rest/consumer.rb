module KafkaRest
  module Consumer
    module ClassMethods
      def topic(t)
        self._topic = t
      end

      def group_name(name)
        self._group_name = name
      end

      def message_format(f)
        if %w(json binary avro).include?(f.to_s)
          self._message_format = f.to_s
        end # raise exception
      end

      def auto_commit(bool)
        self._auto_commit = bool
      end

      def offset_reset(val)
        if %w(smallest largest).include?(val)
          self._offset_reset = val
        end # raise exception
      end

      def max_bytes(val)
        self._max_bytes = val
      end

      # def poll_interval(i)
      #   self._poll_interval = i
      # end
    end

    def self.included(base)
      base.cattr_accessor :_topic
      base.cattr_accessor :_group_name
      base.cattr_accessor :_message_format
      base.cattr_accessor :_auto_commit
      base.cattr_accessor :_offset_reset
      base.cattr_accessor :_max_bytes
      # base.cattr_accessor :_poll_interval

      base.extend ClassMethods
      Worker::ConsumerManager.register!(base)
    end

    def receive(*args)
      raise NotImplemented
    end
  end
end
