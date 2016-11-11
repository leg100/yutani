require 'yutani'

include Yutani

configure(config: 'example/hiera.yaml')

require_relative './modules/vpc'
require_relative './modules/bastion'
require_relative './modules/nginx'

%w[dev staging prod].each do |env|
  # could 'stack' be 'mod'?
  # - one would have to explicitly trigger evaluation phase
  stack project: 'myproject', env: env, region: 'eu-west-1' do
    mod :vpc
    mod :bastion
    mod :nginx
  end.debug
end
