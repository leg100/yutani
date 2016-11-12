require 'hiera'
require 'hashie'
require 'logger'
require 'yutani/dsl_entity'
require 'yutani/mod'
require 'yutani/stack'
require 'yutani/resource'

module Yutani

  @modules = {}

  class << self
    attr_accessor :hiera, :modules, :dir_strategy, :logger
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
  def stack(name, **scope, &block)
    Stack.new(name, **scope, &block)
  end

  def configure(config: 'hiera.yaml', log_level: Logger::DEBUG)
    Yutani.hiera = Hiera.new(:config => config)
    Yutani.logger = Logger.new(STDERR)
    Yutani.logger.level = log_level
  end

  def dir_strategy=(strategy)
    name + scope.values
    Yutani.dir_strategy = stragey
  end

  def dir_strategy(name, scope)
  end

  def set_dir_strategy(name, &block)
    Yutani.dir_strategy[name] = block
    name + scope.values
  end
end
