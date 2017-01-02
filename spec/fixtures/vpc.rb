resource(:aws_vpc, :default) {
  enable_dns_hostnames true
  enable_dns_support   true
  cidr_block           hiera(:cidr_block)
  tags                 {
    Name              env
  }
}

resource(:aws_internet_gateway, :default) {
  vpc_id ref_id(:aws_vpc, :default)

  tags {
    Name env
  }
}

resource(:aws_route_table, :public){
  vpc_id ref_id(:aws_vpc, :default)

  tags {
    Name [env, 'public'].join('-')
  }
}

resource(:aws_route, :public) {
  route_table_id         ref_id(:aws_route_table, :public)
  destination_cidr_block "0.0.0.0/0"
  gateway_id             ref_id(:aws_internet_gateway, :default)
}

hiera(:availability_zones).each {|az, az_info|
  resource(:aws_subnet, :public, az) {
    vpc_id                  ref_id(:aws_vpc, :default)
    cidr_block              az_info['public']
    availability_zone       az
    map_public_ip_on_launch true
    tags                    {
      Name        [env, az, 'public'].join('-')
      Environment env
    }
  }

  resource(:aws_subnet, :private, az) {
    vpc_id                  ref_id(:aws_vpc, :default)
    cidr_block              az_info['public']
    availability_zone       az
    map_public_ip_on_launch false
    tags                    {
      Name        [env, az, 'private'].join('-')
      Environment env
    }
  }

  resource(:aws_eip, :nat, az) { vpc true }

  resource(:aws_nat_gateway, :public, az)  {
    allocation_id ref_id(:aws_eip, :nat, az)
    subnet_id     ref_id(:aws_subnet, :public, az)
  }

  resource(:aws_route_table_association, :public, az) {
    subnet_id      ref_id(:aws_subnet, :public, az)
    route_table_id ref_id(:aws_route_table, :public)
  }

  resource(:aws_route_table, :private, az) {
    vpc_id ref_id(:aws_vpc, :default)

    tags {
      Name [env, az, 'private'].join('-')
    }
  }

  resource(:aws_route_table_association, :private, az) {
    subnet_id      ref_id(:aws_subnet, :private, az)
    route_table_id ref_id(:aws_route_table, :private, az)
  }

  resource(:aws_route, :private, az) {
    destination_cidr_block "0.0.0.0/0"
    route_table_id         ref_id(:aws_route_table, :private, az)
    nat_gateway_id         ref_id(:aws_nat_gateway, :public, az)
  }
}
