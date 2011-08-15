$:.unshift File.expand_path("../lib", __FILE__)
require "magistrate/version"

Gem::Specification.new do |gem|
  gem.name     = "magistrate"
  gem.version  = Magistrate::VERSION

  gem.author   = "Drew Blas"
  gem.email    = "drew.blas@gmail.com"
  gem.homepage = "http://github.com/drewblas/magistrate"
  gem.summary  = "Cluster-based process / worker manager"

  gem.description = gem.summary

  #gem.executables = "magistrate"
  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|lib/|spec/)} }
  #gem.files << "man/magistrate.1"

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'ronn'
  gem.add_development_dependency 'fakefs', '~> 0.2.1'
  gem.add_development_dependency 'rcov',   '~> 0.9.8'
  gem.add_development_dependency 'rr',     '~> 1.0.2'
  gem.add_development_dependency 'rspec',  '~> 2.6.0'
  gem.add_development_dependency "webmock", "~> 1.6.4"
end
