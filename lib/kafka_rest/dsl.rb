module KafkaRest
  module Dsl
    class MissingRequiredOption  < StandardError; end
    class InvalidOptionValue     < StandardError; end

    def option(name, opts = {})
      name         = name.to_s
      default      = opts[:default]
      validate     = opts[:validate] || ->(val) { true }
      error_msg    = opts[:error_message] || "`#{name}`'s value is invalid"

      class_eval do
        metaclass = class << self; self; end
        instance_variable_set "@#{name}", default
        metaclass.send :define_method, "_validate_#{name}", ->(val) { validate.call(val) }
      end

      class_eval %Q{
        def #{name}
          self.class.get_#{name}
        end

        class << self
          def get_#{name}
            @#{name}
          end

          def #{name}(val)
            unless _validate_#{name}(val)
              raise KafkaRest::Dsl::InvalidOptionValue.new("#{error_msg}")
            end

            @#{name} = val
          end
        end
      }
    end
  end
end
