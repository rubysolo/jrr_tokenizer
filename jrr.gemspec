# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jrr/version"

Gem::Specification.new do |spec|
  spec.name          = "jrr"
  spec.version       = Jrr::VERSION
  spec.authors       = ["Solomon White"]
  spec.email         = ["rubysolo@gmail.com"]

  spec.summary       = %q{parse strings into fantastic tokens}
  spec.homepage      = "https://github.com/rubysolo/jrr_tokenizer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
