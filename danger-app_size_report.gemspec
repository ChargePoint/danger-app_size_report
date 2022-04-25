# frozen_string_literal: true

require 'English'
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'app_size_report/gem_version'

Gem::Specification.new do |spec|
  spec.name          = 'danger-app_size_report'
  spec.version       = AppSizeReport::VERSION
  spec.authors       = ['Rishab Sukumar', 'Bharath Thakkallapally', 'Vido Shaweddy']
  spec.email         = ['rishab.sukumar@chargepoint.com']
  spec.description   = 'A Danger plugin for reporting iOS and Android app size violations.'
  spec.summary       = 'A Danger plugin for reporting iOS and Android app size violations. A valid App Thinning Size Report or Android App Bundle must be passed to the plugin for accurate functionality.'
  spec.homepage      = 'https://github.com/ChargePoint/danger-app_size_report'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.6.0'
  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'danger-plugin-api', '~> 1.0'

  # General ruby development
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'

  # Testing support
  spec.add_development_dependency 'rspec', '~> 3.4'

  # Linting code and docs
  spec.add_development_dependency 'rubocop', '~> 1.25.0'
  spec.add_development_dependency 'yard', '~> 0.9.27'

  # Makes testing easy via `bundle exec guard`
  spec.add_development_dependency 'guard', '~> 2.14'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'

  # If you want to work on older builds of ruby
  spec.add_development_dependency 'listen', '3.0.7'

  # This gives you the chance to run a REPL inside your tests
  # via:
  #
  #    require 'pry'
  #    binding.pry
  #
  # This will stop test execution and let you inspect the results
  spec.add_development_dependency 'pry', '~> 0.14.1'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
