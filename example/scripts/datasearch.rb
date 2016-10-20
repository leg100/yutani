require 'yutani'

include Yutani

configure(config: 'hiera.yaml')

require_relative './modules/vpc'
require_relative './modules/bastion'
require_relative './modules/nginx'

%w[dev staging prod].each do |env|
  stack project: 'myproject', env: env, region: 'eu-west-1' do
    include_mod :vpc
    include_mod :bastion
    include_mod :nginx
  end
end

tar!
