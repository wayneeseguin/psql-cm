lib = File.expand_path('../lib/', __FILE__)

$:.unshift lib unless $:.include?(lib)

require 'psql-cm/version'

Gem::Specification.new do |spec|
  spec.platform    = Gem::Platform::RUBY
  spec.version     = ::PSQLCM::Version
  spec.name        = 'psql-cm'
  spec.authors     = ['Wayne E. Seguin']
  spec.email       = ['wayneeseguin@gmail.com']
  spec.homepage    = 'http://rubygems.org/gems/psql-cm/'
  spec.summary     = 'PostgreSQL CM'
  spec.description = 'PostgreSQL Change Management Tool'

  spec.required_ruby_version = '~> 1.9.3'
  spec.required_rubygems_version = '>= 1.8.22'
  spec.add_dependency 'pg', '>= 0.13.2'

  spec.require_path = 'lib'
  spec.executables  = ['psql-cm']
  spec.files        = Dir.glob('{bin,lib}/**/*') + %w(LICENCE README.md History.md)
  spec.test_files   = Dir.glob('spec/**/*')
end

