require 'hiera'
require 'hashie'
require 'logger'
require 'docile'
require 'yutani/version'
require 'yutani/config'
require 'yutani/hiera'
require 'yutani/cli'
require 'yutani/dsl_entity'
require 'yutani/reference'
require 'yutani/directory_tree'
require 'yutani/stack'
require 'yutani/scope'
require 'yutani/resource'
require 'yutani/provider'
require 'yutani/utils'

module Yutani

  @stacks = []

  class << self
    attr_accessor :hiera, :stacks, :logger
  end

  class << self
    def logger
      @logger ||= (
        logger = Logger.new(STDOUT)
        logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'INFO'))
        logger
      )
    end

    def stack(*identifiers, **scope, &block)
      s = Stack.new(*identifiers, **scope, &block)
      @stacks << s
      s
    end

    def config(override = {})
      config = Config.new
      override = Config[override]

      config = config.read_config_file

      # Merge DEFAULTS < .yutani.yml < override
      Config.from(config.merge(override))
    end

    def dsl_eval(str, *args, &block)
      Docile.dsl_eval(self, *args, &block)
    end

    def eval_string(*args, str, file)
      dsl_eval(str, *args, file) do
        instance_eval(str, file)
      end
    end

    def eval_file(*args, file)
      eval_string(File.read(file), file)
    end
  end
end

# Although deprecated, the timeout stdlib in ruby 2.3.1 adds #timeout
# to Object. At least one resource (aws_elb) has a property called
# 'timeout', which, like all property names we'd like to be sent to method_missing,
# but doesn't because of Object#timeout!
# (Yutani itself doesn't actually need timeout, but there is a lib somewhere (?)
# require'ing it, so it gets loaded)
Object.send :remove_method, :timeout
