# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid_friendship/version'

Gem::Specification.new do |spec|
  spec.name          = "mongoid_friendship"
  spec.version       = MongoidFriendship::VERSION
  spec.authors       = ["Yang Wang"]
  spec.email         = ["sinoyang@gmail.com"]
  spec.description   = %q{make friends among users}
  spec.summary       = %q{Ability to make a two way friendship}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.add_dependency 'mongoid', '>= 3.0'
  spec.add_dependency 'activesupport', '>= 3.2'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
