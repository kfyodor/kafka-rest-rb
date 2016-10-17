# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kafka_rest/version'

Gem::Specification.new do |spec|
  spec.name          = "kafka-rest-rb"
  spec.version       = KafkaRest::VERSION
  spec.authors       = ["Theodore Konukhov"]
  spec.email         = ["me@thdr.io"]

  spec.summary       = %q{Kafka-REST proxy client for Ruby on Rails.}
  spec.description   = %q{Kafka-REST client, DSLs and consumer workers for Ruby.}
  spec.homepage      = "https://github.com/konukhov/kafka-rest-rb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = ['kafka-rest']
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'faraday', '~> 0.9'
  spec.add_runtime_dependency 'faraday_middleware', '~> 0.10'
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_runtime_dependency 'multi_json', '~> 1.12'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
