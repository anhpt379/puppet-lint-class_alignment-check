# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = 'puppet-lint-class_params_alignment-check'
  spec.version     = '1.0.0'
  spec.homepage    = 'https://github.com/anhpt379/puppet-lint-class_params_alignment-check'
  spec.license     = 'MIT'
  spec.author      = 'Anh Pham'
  spec.email       = 'anhpt379@gmail.com'
  spec.files = Dir[
    'README.md',
    'LICENSE',
    'lib/**/*',
    'spec/**/*',
  ]
  spec.test_files  = Dir['spec/**/*']
  spec.summary     = 'A puppet-lint plugin to check & fix class params alignment.'
  spec.description = <<-DESC
  A puppet-lint plugin to check & fix class params alignment.
  DESC

  spec.add_dependency             'puppet-lint'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its', '~> 1.0'
  spec.add_development_dependency 'rspec-collection_matchers', '~> 1.0'
end
