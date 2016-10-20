lib = File.expand_path("../lib/", __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'yutani/version'

Gem::Specification.new do |s|
  s.name        = 'yutani'
  s.version     = Yutani::VERSION
  s.date        = '2016-08-23'
  s.summary     = "Terraform DSL"
  s.description = "Generates JSON for Terraform"
  s.authors     = ["Louis Garman"]
  s.email       = 'louisgarman@gmail.com'
  s.files       = Dir['bin/*', 'lib/**/*.rb']
  s.homepage    = 'http://rubygems.org/gems/yutani'
  s.license     = 'MIT'
  s.executables << 'yutani'
end
