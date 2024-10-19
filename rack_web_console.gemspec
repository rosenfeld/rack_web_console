# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack_console/version'

Gem::Specification.new do |spec|
  spec.name          = 'rack_web_console'
  spec.version       = RackConsole::VERSION
  spec.authors       = ['Rodrigo Rosenfeld Rosas']
  spec.email         = ['rr.rosas@gmail.com']

  spec.summary       = %q{A web console for Rack apps.}
  spec.homepage      = 'https://github.com/rosenfeld/rack_web_console'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.5'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'rspec', '~> 3.13.0'
  spec.add_development_dependency 'rack', '~> 3.1'
  spec.add_development_dependency 'puma', '~> 6.4.3'
  spec.add_development_dependency 'rails', '~> 7.2.1'
end
