mod :vpc do
  resource :aws_vpc, :main do
    enable_dns_hostnames true
    cidr_block           hiera(:cidr_block)
    tags                 ({
      Name:              [scope[:project], scope[:env]].join('-'),
      Environment:       scope[:env]
    })
  end

  hiera(:subnets).map do |net|
    resource :aws_subnet, [net[:type], net[:az]].join('_') do
      vpc_id                  resources[:aws_vpc][:main].id
      cidr_block              net[:cidr_block]
      availability_zone       net[:az]
      map_public_ip_on_launch (net[:type] == 'public')
      tags                    ({
        Name:                 [scope[:project], scope[:env], net[:az]].join('-'),
        Environment:          scope[:env]
      })
    end
  end
end
