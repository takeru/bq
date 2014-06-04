# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bq/version'

Gem::Specification.new do |spec|
  spec.name          = "bq"
  spec.version       = Bq::VERSION
  spec.authors       = ["sasaki takeru"]
  spec.email         = ["sasaki.takeru@gmail.com"]
  spec.summary       = %q{Just execute (Big)query.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/takeru/bq"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'google-api-client'
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "terminal-table"
end
