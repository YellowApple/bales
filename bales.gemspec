lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bales/version'

Gem::Specification.new do |gem|
  gem.name        = "bales"
  gem.version     = Bales::VERSION
  gem.authors     = ["Ryan S. Northrup"]
  gem.email       = ["northrup@yellowapple.us"]
  gem.summary     = "Ruby on Bales"
  gem.description = "A framework for building command-line applications"
  gem.homepage    = "http://github.com/YellowApple/bales"
  gem.files       = Dir.glob("lib/**/*") + %w( README.md )
  gem.license     = "MIT"
end
