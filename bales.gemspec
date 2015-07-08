lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bales/version'

Gem::Specification.new do |gem|
  gem.name = "bales"
  gem.version = Bales::VERSION
  gem.authors = ["Ryan S. Northrup"]
  gem.email = ["rnorthrup@newleaders.com"]
  gem.summary = "Ruby on Bales command-line app framework"
  gem.files = Dir.glob("lib/**/*") + %w( README.md )
  gem.license = "MIT"
end
