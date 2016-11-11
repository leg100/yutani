require 'hiera'
require 'hashie'
require 'yutani/dsl_entity'
require 'yutani/mod'
require 'yutani/stack'
require 'yutani/resource'

module Yutani

  @modules = {}

  class << self
    attr_accessor :hiera, :modules
  end

  # block is mandatory
  # top-level module; not within stack
  # therefore it is not evaluated, but added
  # to global hash
  def mod(name, **scope, &block)
    raise "Must provide block to module #{name}" unless block_given?

    Yutani.modules[name] = {scope: scope, block: block}
  end

  # a special module that gets evaluated immedi.
  def stack(**scope, &block)
    Stack.new(**scope, &block)
  end

  def configure(config: 'hiera.yaml')
    Yutani.hiera = Hiera.new(:config => config)
  end
end
