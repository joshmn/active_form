# frozen_string_literal: true

require_relative "lib/active_form/version"

Gem::Specification.new do |spec|
  spec.name        = 'active_form'
  spec.version     = ActiveForm::VERSION
  spec.authors     = ['Josh']
  spec.email       = ['josh@josh.mn']
  spec.homepage    = 'https://github.com/joshmn/active_form'
  spec.summary     = 'A form object that really wants to be a form object.'
  spec.description = spec.summary
  spec.license     = 'MIT'

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'rails', '>= 5.2'

  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-rails'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'codecov'
end

