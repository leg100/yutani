# Yutani

[![Build Status](https://travis-ci.org/leg100/yutani.svg?branch=master)](https://travis-ci.org/leg100/yutani)

A Ruby DSL for generating Terraform code.

## Principles

* Yutani eschews Terraform variables in favour of querying Hiera. Terraform variables have one advantage: you can inject sensitive information you'd rather not have stored in plaintext in the JSON files.
* Terraform modules are not generally reusable. HCL limits their flexibility. They do have one advantage: they permit one to 'target' logical groups of multiple resources at plan/apply time. They're retained for that reason alone.


## Stack

Maps to a Terraform stack, the directory from which you'd run commands like `terraform plan` and `terraform apply`. It takes two parameters: a name, and a hash, which sets the Hiera scope. For example:

```ruby
stack :mystack, env: 'dev', region: 'eu-west-1' do
env
```

Sets the stack name to `:mystack`, and sets the Hiera scope to `{env: 'dev', region: 'eu-west-1'}`.

## Modules

Maps to a terraform module. `stack` is a module too, mapping to the `root` module in Terraform. Child modules can be created within a stack. Because of the clash with the ruby `module` keyword, `mod` is used instead. 

This object maps to a Terraform module, generating a reference to the module. Any source is supported, however this object is at its most powerful when used to generate a local directory of resources (the "local file path" source type). These resources are specified within the block passed to the module.

Modules are optional. A resource can be specified:w


* Only one paramter can be passed to a module, and that is the name of the module. This can be a string or a symbol. This sets the scope variable `module_path`.

## Resources

### Terraform

* Every stack is an object of type Stack; and has many modules
* Every module is an object of type Module; and has many resources
* Every resource is an object of type Resource; and has many attributes

### Ansible

* Every playbook is an object of type Playbook
* Every task is an object of type Task


* A resource has at the very least a resource type specified as a ruby symbol. 
* If a name isn't specified, then the module name is used. When there is more than one instance of a resource type in a module, an error will be raised.
* A name is specified with an array. The elements will be concatenated with an underscore to generate the terraform name. The elements can be symbols or strings, or hashes.
* If a hash is specified, the values will be concatenated with an underscore to generate the name. Values can be symbols or strings. A nested hash will raise an error. Hashes also set the hiera scope.


## Rationale

Directly writing Terraform configuration files in its native HCL has severe limitations. The main one is that HCL lacks the expressive power to create reusable blocks of code, whether that be its modules or stacks. Yutani overcomes this obstacle by providing the power of ruby to generate configuration files. It can create also directory trees containing multiple stacks, and local modules. It generates JSON, which terraform also supports (There is no HCL generator for ruby that I know of).

## Resource

A Resource object represents an individual Terraform resource.

## Modules

A Module object maps to a Terraform module. As well as supporting all th usual source parameters, it can also be used to both create both a local directory of configuration files and the reference to it.

## Stack

A Stack object generates a directory of configuration files and/or  directories of local modules.

## Dependencies

Terraform dependencies 

# Notes

* blocks and hashes can be used interchangely for sub-resources
* `{}` and `({})` for property values, represent blocks and hashes respectively
* Resource property names can clash with ruby method names, i.e. `timeout 60` in an `aws_elb`'s health check will actually call Object.timeout in ruby. To get around this, prefix the name with an underscore, i.e. `_timeout 60`, and Yutani will remove the underscore after evaluation. (This is to do with Yutani relying on something called `method_missing` in ruby, whereby all unknown method calls are instead coverted to resource property names. This won't work alas in the case just talked about!).
