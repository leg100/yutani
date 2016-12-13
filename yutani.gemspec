lib = File.expand_path("../lib/", __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'yutani/version'

Gem::Specification.new do |s|
  s.name                  = 'yutani'
  s.version               = Yutani::VERSION
  s.date                  = '2016-11-29'
  s.summary               = "Terraform DSL"
  s.description           = "Generates JSON for Terraform"
  s.required_ruby_version = ['~> 2.3', '>= 2.3.1']
  s.authors               = ["Louis Garman"]
  s.email                 = 'louisgarman+yutani@gmail.com'
  s.files                 = Dir['bin/*', 'lib/**/*.rb']
  s.homepage              = 'https://github.com/leg100/yutani'
  s.license               = 'MIT'

  s.require_paths = ["lib"]
  s.executables << 'yutani'

  s.add_runtime_dependency 'activesupport', '~> 5'
  s.add_runtime_dependency 'hashie', '~> 3.4.3', '>= 3.4.3'
  s.add_runtime_dependency 'hiera', '~> 3.2', '>= 3.2.1'
  s.add_runtime_dependency 'thor', '~> 0.19.1'
  s.add_runtime_dependency 'docile', '~> 1.1', '>= 1.1.5'
  s.add_runtime_dependency 'guard', '~> 2.14.0'
  s.add_runtime_dependency 'guard-yield'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'aruba', '~> 0.14.2'
end
