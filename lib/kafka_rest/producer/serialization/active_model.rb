module KafkaRest
  module Producer
    module Serialization
      class ActiveModel < Adapter
        def serialize(obj, opts = {})
          klass.new(obj, opts).as_json
        end

        private

        def klass
          @klass ||= (
            unless defined?(ActiveModel::Serializer)
              'ActiveModel::Serializer cannot be found'
            end

            if (kl = @args.first) && kl < ActiveModel::Serializer
              kl
            else
              raise 'Provide ActiveModel::Serializer child as an argunent to `serializer`'
            end
          )
        end
      end
    end
  end
end
