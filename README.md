# Yutani

[![Build Status](https://travis-ci.org/leg100/yutani.svg?branch=master)](https://travis-ci.org/leg100/yutani)

## About

Yutani - A ruby DSL for generating [Terraform](https://github.com/hashicorp/terraform/) configurations:

* Eschews Terraform variables in favour of querying [Hiera](https://github.com/puppetlabs/hiera)
* Dismisses Terraform modules; everything is in a single 'root' module
* Introduces the concept of scopes and dimensions
* Permits targeting resources based on dimensions
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
stack(:nginx) {
	resource(:aws_instance) {
		ami           "ami-123123"
		instance_type "t2.micro"
		key_name      "my-ssh-key"
	}
}
```

produces `./terraform/nginx.tf`:

```hcl
resource "aws_instance" "nginx" {
	ami           = "ami-123123"
	instance_type = "t2.micro"
	key_name      = "my-ssh-key"
}
```

Yutani integrates with [Hiera](https://github.com/puppetlabs/hiera). Variables can be looked up by key:

```ruby
stack(:nginx) {
	resource(:aws_instance) {
		ami           hiera(:ami)
		instance_type "t2.micro"
		key_name      "my-ssh-key"
	}
}
```

Given a YAML file at `./hiera/common.yaml`:

```yaml
---
ami: ami-123123
```

again, produces `./terraform/nginx.tf`:

```hcl
resource "aws_instance" "nginx" {
	ami           = "ami-123123"
	instance_type = "t2.micro"
	key_name      = "my-ssh-key"
}
```

## Usage

### Stack

A stack object creates a directory containing Terraform configuration. This is the same directory from which you'd run commands like `terraform plan` and `terraform apply`. It takes two optional parameters: 

* _identifiers_ - one or more symbols
* _hiera scope_ - a single level hash

For example:

```ruby
stack(:mystack, env: 'dev', region: 'eu-west-1')
```

Has an identifier `:mystack`, and a hiera scope `{env: 'dev', region: 'eu-west-1'}`.

The hiera scope determines which variables are looked up. 

Identifiers and hiera scope values together determine the stack name. In this case the stack directory would be:

```
./terraform/mystack_dev_eu_west_1
```

### Resource

A resource maps to a Terraform resource. It takes two parameters:

* _resource type_ - mandatory, i.e. `aws_instance`
* _identifiers_ - optional array of symbols or strings
* _hiera scope_ - hiera scope hash

The resource name is constructed from both a resource's identifiers and the hiera scope values, as well as those of the scopes under which it falls, following these rules:

* Resources at the stack level inherit the first stack identifier. If no identifiers are defined, it's set to `root`.
* Resources within a scope are named according to the scope's identifiers and hiera scope values. Stack identfiers and hiera scope values are *not* used.
* Resources within a nested scope inherit identifiers and hiera scope values from each and every nested scope. Stack identfiers and hiera scope values are *not* used.

For example:

```ruby
stack(:mystack) {
	scope(:public) {
		scope(az: 'eu-west-1a') {
			resource(:aws_subnet, :spare)
		}
	}
}
```

The `aws_subnet` resource would be named `public_eu_west_1a_spare`. (Note: any hyphens are converted to underscores).

### Includes

You can include DSL code from other files:

```ruby
stack(:mystack) {
	inc { './nginx.rb' }
}
```


## Style

I've opted for using `{}` instead of `do; end` for the blocks in the examples. Either can of course be used, but I wanted to convey the similarity to HCL (which does use curly brackets).

## Notes

* Either blocks and hashes can be used for sub-resources (i.e. `tags` in `aws_instance`, or `listener` in `aws_elb`)
* `{}` and `({})` for property values, represent blocks and hashes respectively
* Makes heavy use of ruby's `method_missing`. Basically, Yutani knows nothing of which providers and resources are possible, it just converts the resource property names to methods, and passes the property values as parameters. While this means Yutani doesn't have to keep track of the continual changes to Terraform's resources, it does make it more brittle than I'd like. For instance, the resource `aws_security_group_rule` has a property called `self`, which is of course also a ruby keyword, and if it is defined in this way it will trigger an error. To get around this, pass a parameter to your resource block like so:

```ruby
resource(:aws_security_group_rule) {|r|
    r.type              "ingress"
    r.from_port         22
    r.to_port           22
    r.protocol          "tcp"
    r.self              true
    r.security_group_id "sg-123456"
}
```

Not so pretty, but you'll be alright.

## Roadmap

* Rewrite in golang, evaluating the ruby DSL via mruby 
* Support Ansible, Packer, and any other tools that rely on a serialization format for configuration
* Support for setting remote config via DSL
* Support for files and templates. Consider whether this can be done at evaluation stage and placed inline into generated JSON

## Issues that this will overcome

* Unable to selectively enable SSL on an ELB
* Add more as I think of em!