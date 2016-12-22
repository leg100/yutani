# Yutani

[![Build Status](https://travis-ci.org/leg100/yutani.svg?branch=master)](https://travis-ci.org/leg100/yutani)

## About

Yutani - A ruby DSL for generating [Terraform](https://github.com/hashicorp/terraform/) configurations:

* Eschews Terraform variables in favour of querying [Hiera](https://github.com/puppetlabs/hiera)
* No Terraform modules; everything is in a single 'root' module
* Generates multiple configurations or 'stacks'
* Generates JSON rather than HCL


## Installation

Ensure you have at least version 2.3.1 of ruby installed.

Install the gem:

```sh
gem install yutani
```

Initialise a directory structure and configuration file with defaults:

```sh
yutani init
```


## Examples

The DSL bears a strong similarity to the Terraform HCL syntax:

```ruby
stack {
	resource(:aws_instance, :nginx) {
		ami           "ami-123123"
		instance_type "t2.micro"
		key_name      "my-ssh-key"
	}
}
```

Yutani integrates with [Hiera](https://github.com/puppetlabs/hiera). Variables can be looked up by key:

```ruby
stack {
	resource(:aws_instance, :nginx) {
		ami           hiera(:ami)
		instance_type "t2.micro"
		key_name      "my-ssh-key"
	}
}
```

You can create multiple stacks, each with a different Hiera scope:

```ruby
%w[dev staging prod].each do |env|
	stack(env: env) {
		resource(:aws_instance, :nginx) {
			ami           hiera(:ami)
			instance_type hiera(:instance_type)
			key_name      "my-ssh-key"
		}
	}
end
```

Depending on your Hiera hierarchy each stack can have different ami and instance_type, optionally falling back on a default.


## Objects

### Stack

A stack object creates a directory containing Terraform configuration. This is the same directory from which you'd run commands like `terraform plan` and `terraform apply`. It takes the following parameters:

* _namespace_ - optional symbols
* _hiera scope_ - a single level hash

For example:

```ruby
stack(:mystack, env: 'dev', region: 'eu-west-1')
```

Has the namespace `:mystack`, and a hiera scope `{env: 'dev', region: 'eu-west-1'}`.

The hiera scope determines which variables are looked up in the Hiera hierarchy.

The namespace is joined together with the hiera scope _values_ to form the resulting stack directory. In this case the directory would be:

```
./terraform/mystack_dev_eu_west_1
```

### Resource

A resource maps to a Terraform resource. It takes the following parameters:

* _resource type_ - mandatory, symbol, i.e. `:aws_instance`
* _resource names_ - mandatory, symbols, i.e. `:app, :frontend`

The _resource names_ are joined together with an underscore to form the resulting Terraform resource name, i.e.:

```ruby
resource(:aws_instance, :app, :backend, :v2)
```

would result in a Terraform resource named `app_backend_v2`.


### References

Use the `ref()` function to make references to other resources and their attributes. It takes the form:

`ref(resource_type, *resource_names, attr)`

Alternatively, you can use the syntax `ref_X()` to refer to a particular attribute, e.g. referencing the `id` attribute of a resource:

`ref_id(resource_type, *resource_names)`

### Includes

You can include DSL code from other files:

```ruby
stack {
	inc { './nginx.rb' }
}
```

## Style

I've opted for using `{}` instead of `do; end` for the blocks in the examples. Either can of course be used, but I wanted to convey the similarity to HCL.

## Notes

* Either blocks and hashes can be used for sub-resources (i.e. `tags` in `aws_instance`, or `listener` in `aws_elb`)
* `{}` and `({})` for property values, represent blocks and hashes respectively
* Makes heavy use of ruby's `method_missing`. Basically, Yutani knows nothing of which providers and resources are possible, it just converts the resource property names to methods, and passes the property values as parameters. While this means Yutani doesn't have to keep track of the continual changes to Terraform's resources, it does make it more brittle than I'd like. For instance, the resource `aws_security_group_rule` has a property called `self`, which is of course also a ruby keyword, and if it is defined in this way it will trigger an error. To get around this, pass a parameter to your resource block like so:

```ruby
resource(:aws_security_group_rule, :bastion) {|r|
    type              "ingress"
    from_port         22
    to_port           22
    protocol          "tcp"
    r.self            true
    security_group_id "sg-123456"
}
```

Not so pretty, but you'll be alright.

## Roadmap

* Rewrite in golang, evaluating the ruby DSL via mruby 
* Investiate supporting Ansible, Packer, and any other tools that rely on a serialization format for configuration
* Support for setting remote config via DSL
* Support for files and templates. Consider whether this can be done at evaluation stage and placed inline into generated JSON

## Issues that this will overcome

* Unable to selectively enable SSL on an ELB
* Add more as I think of em!