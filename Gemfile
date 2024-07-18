# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'debug'
gem 'rspec-collection_matchers'

group :coverage, optional: ENV['COVERAGE'] != 'yes' do
  gem 'codecov', require: false
  gem 'simplecov-console', require: false
end
