module KafkaRest
  module Dsl
    # TODO validate required fields at some moment

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

      class_eval do
        metaclass = class << self; self; end
        instance_variable_set "@#{name}", default
        metaclass.send :define_method, "validate_#{name}", ->(val) { validate.call(val) }
      end

      class_eval %Q{
        def #{name}
          self.class.instance_variable_get("@#{name}")
        end

        class << self
          def _#{name}
            @#{name}
          end

          def #{name}(val)
            unless validate_#{name}(val)
              raise KafkaRest::Dsl::InvalidOptionValue.new("#{error_msg}")
            end

            @#{name} = val
          end
        end
      }
    end
  end
end
