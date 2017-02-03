# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active-record-ex/version'

Gem::Specification.new do |spec|
  spec.name          = 'active-record-ex'
  spec.version       = ActiveRecordEx::VERSION
  spec.authors       = ['Arjun Kavi', 'PagerDuty']
  spec.email         = ['arjun.kavi@gmail.com', 'developers@pagerduty.com']
  spec.license       = 'MIT'
  spec.summary       = 'Relation -> Relation methods'
  spec.description   = 'A library to make ActiveRecord::Relations even more awesome'
  spec.homepage      = 'https://github.com/PagerDuty/active-record-ex'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'shoulda'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'minitest-rails'
  spec.add_development_dependency 'test-unit'

  spec.add_runtime_dependency 'activesupport', '>= 3.2'
  spec.add_runtime_dependency 'activerecord', '>= 3.2'
end
