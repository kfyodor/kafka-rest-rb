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
      name         = name.to_s
      default      = opts[:default]
      validate     = opts[:validate] || ->(val) { true }
      error_msg    = opts[:error_message] || "`#{name}`'s value is invalid"
      with_options = opts[:with_options] || false

      class_eval do
        metaclass = class << self; self; end
        instance_variable_set "@#{name}", default
        metaclass.send :define_method, "validate_#{name}", ->(val) { validate.call(val) }
      end

      class_eval %Q{
        def #{name}
          self.class._#{name}
        end

        class << self
          def _#{name}
            @#{name}
          end
        end
      } + (
        if with_options
          %Q{
            def #{name}_options
              self.class._#{name}_options
            end

            class << self
              def #{name}(val, options = {})
                unless validate_#{name}(val)
                  raise KafkaRest::Dsl::InvalidOptionValue.new("#{error_msg}")
                end

                @#{name} = val
                @#{name}_options = options
              end

              def #{name}_options(options)
                @#{name}_options = options
              end

              def _#{name}_options
                @#{name}_options
              end
            end
          }
        else
          %Q{
            class << self
              def #{name}(val)
                unless validate_#{name}(val)
                  raise KafkaRest::Dsl::InvalidOptionValue.new("#{error_msg}")
                end

                @#{name} = val
              end
            end
          }
        end
      )
    end
  end
end
