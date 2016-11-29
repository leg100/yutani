require 'hiera'
require 'hashie'
require 'logger'
require 'yutani/dsl_entity'
require 'yutani/reference'
require 'yutani/directory_tree'
require 'yutani/mod'
require 'yutani/stack'
require 'yutani/resource'

module Yutani

  @modules = {}

  class << self
    attr_accessor :hiera, :modules, :logger
  end

  @logger = Logger.new(STDERR)
  @logger.level = Logger::INFO

  # block is mandatory
  # top-level module; not within stack
  # therefore it is not evaluated, but added
  # to global hash
  def mod(name, **scope, &block)
    raise "Must provide block to module #{name}" unless block_given?

    Yutani.modules[name] = {scope: scope, block: block}
  end

  # a special module that gets evaluated immedi.
  def stack(name, **scope, &block)
    Stack.new(name, **scope, &block)
  end

  def configure(config: 'hiera.yaml')
    Yutani.hiera = Hiera.new(:config => config)
  end
end
