module KafkaRest
  module Dsl
    class MissingRequiredOption < StandardError;
      def initialize(name)
        super("Missing required option `#{name}`")
      end
    end

    class InvalidOptionValue < StandardError; end

    def option(name, opts = {})
      name      = name.to_s
      default   = opts[:default]
      validate  = opts[:validate] || ->(val) { true }
      error_msg = opts[:error_message] || "`#{name}`'s value is invalid"
      required  = opts[:required] || false

      class_eval do
        metaclass = class << self; self; end
        class_variable_set "@@#{name}", default
        metaclass.send :define_method, "validate_#{name}", &validate
      end

      class_eval %Q{
        def #{name}
          @@#{name}
        end

        def self._#{name}
          @@#{name}
        end

        def self.#{name}(val)
          if #{required} && val == nil
            raise KafkaRest::Dsl::MissingRequiredOption.new("#{name}")
          end

          unless validate_#{name}(val)
            raise KafkaRest::Dsl::InvalidOptionValue.new("#{error_msg}")
          end

          @@#{name} = val
        end
      }
    end
  end
end
