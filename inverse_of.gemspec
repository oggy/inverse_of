$:.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'inverse_of/version'

Gem::Specification.new do |s|
  s.name        = 'inverse_of'
  s.date        = Date.today.strftime('%Y-%m-%d')
  s.version     = InverseOf::VERSION.join('.')
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["George Ogata"]
  s.email       = ["george.ogata@gmail.com"]
  s.homepage    = "http://github.com/oggy/inverse_of"
  s.summary     = "Backport of ActiveRecord 2.3.6's inverse associations."
  s.description = <<-EOS.gsub(/^ *\|/, '')
    |Adds the :inverse option to Active Record associations for Active
    |Record 2.3.0 -- 2.3.5.
  EOS

  s.add_dependency 'activerecord', '< 2.3.6'
  s.add_development_dependency 'ritual'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'sqlite3-ruby'
  if RUBY_ENGINE == 'ruby' && RUBY_VERSION >= '1.9'
    s.add_development_dependency 'ruby-debug19'
  else
    s.add_development_dependency 'ruby-debug'
  end
  s.required_rubygems_version = ">= 1.3.6"
  s.files = Dir["lib/**/*"] + %w(LICENSE README.markdown Rakefile CHANGELOG)
  s.require_path = 'lib'
end
