require 'yutani'

include Yutani

mod :bastion do
  resource :aws_security_group, :bastion do
    name        [scope[:module_name], scope[:env]].join('-')
    description "Security group for the bastion instance"
    vpc_id      modules[:vpc].resources[:aws_vpc][:main].id
  end

  resource :aws_security_group_rule, :bastion do
    type              'ingress'
    security_group_id resources[:aws_security_group][:bastion].id
    cidr_blocks       hiera(:allowable_ip_ranges)
    from_port         22
    to_port           22
    protocol          'tcp'
  end

  resource :aws_instance, :bastion do
    instance_type          hiera(:instance_type)
    vpc_security_group_ids [
      resources[:aws_security_group][:bastion].id
    ]
    ami                    hiera(:ami)
    key_name               hiera(:key_name)
    tags                   ({
      Name:                  [scope[:project], scope[:module_name], scope[:env]],
      Role:                  scope[:module_name],
      Environment:           scope[:env]
    })
  end
end
