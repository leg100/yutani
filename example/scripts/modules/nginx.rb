mod :nginx do
  resource :aws_instance, :nginx do
    instance_type          hiera(:instance_type)
    vpc_security_group_ids [
      resources[:aws_security_group][:instance].id
    ]
    ami                    hiera(:ami)
    key_name               hiera(:key_name)
    tags                   ({
      Name:                  [scope[:project], scope[:module_name], scope[:env]].join('-'),
      Role:                  scope[:module_name],
      Environment:           scope[:env]
    })
  end

  resource :aws_security_group, :instance do
    name        [scope[:module_name], scope[:env]].join('-')
    description "Security group for the nginx instance"
    vpc_id      modules[:vpc].resources[:aws_vpc][:main].id
  end

  resource :aws_security_group_rule, :instance_http_from_elb do
    type                     'ingress'
    security_group_id        resources[:aws_security_group][:instance].id
    source_security_group_id resources[:aws_security_group][:elb].id
    from_port                80
    to_port                  80
    protocol                 'tcp'
  end

  resource :aws_security_group_rule, :instance_ssh_from_bastion do
    type                     'ingress'
    security_group_id        resources[:aws_security_group][:instance].id
    source_security_group_id modules[:bastion].resources[:aws_security_group][:bastion].id
    from_port                22
    to_port                  22
    protocol                 'tcp'
  end

  resource :aws_elb, :nginx do
    name                      [scope[:project], scope[:env], scope[:module_name]].join('-')
    subnets                   modules[:vpc].resources[:aws_subnet].values.map(&:id).grep(/public/)
    cross_zone_load_balancing true
    connection_draining       true
    internal                  false
    security_groups           [resources[:aws_security_group][:elb].id]

    tags                      ({
      Name:                   [scope[:project], scope[:env], scope[:module_name]].join('-'),
      Project:                scope[:project],
      Env:                    scope[:env],
      Role:                   scope[:module_name]
    })

    listener                  do
      instance_port           80
      instance_protocol       "http"
      lb_port                 80
      lb_protocol             "http"
    end

    health_check              do
      healthy_threshold       2
      unhealthy_threshold     2
      timeout                 2
      target                  "HTTP:80/"
      interval                5
    end

    lifecycle                 do
      create_before_destroy   true
    end
  end

  resource :aws_security_group, :elb do
    name        [scope[:project], scope[:env], scope[:module_name], 'elb'].join('-')
    vpc_id      modules[:vpc].resources[:aws_vpc][:main].id
    description "Security group for elb of the nginx cluster"
  end

  # public ingress to elb
  resource :aws_security_group_rule, :elb_http_from_public do
    type           'ingress'
    security_group resources[:aws_security_group][:elb].id
    cidr_blocks    ['0.0.0.0/0']
    from_port      80
    to_port        80
    protocol       'tcp'
  end

  # egress to instance
  resource :aws_security_group_rule, :elb_http_to_instance do
    type                     'egress'
    security_group           resources[:aws_security_group][:elb].id
    source_security_group_id resources[:aws_security_group][:instance].id
    from_port                80
    to_port                  80
    protocol                 'tcp'
  end
end
