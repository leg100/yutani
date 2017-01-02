begin; require 'pry'; rescue LoadError; end

require 'logger'
require 'docile'

require 'yutani/version'
require 'yutani/config'
require 'yutani/hiera'
require 'yutani/cli'
require 'yutani/dsl_entity'
require 'yutani/directory_tree'
require 'yutani/stack'
require 'yutani/resource'
require 'yutani/provider'
require 'yutani/utils'

module Yutani
  @stacks = []

  class << self
    # do we need :logger?
    attr_accessor :hiera, :stacks, :logger

    def logger
      @logger ||= (
        logger = Logger.new(STDERR)
        logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'INFO'))
        logger
      )
    end

    # DSL statement
    def stack(*namespace, &block)
      s = Stack.new(*namespace, &block)
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

    def scope(**kv, &block)
      Hiera.push kv
      yield kv.values
      Hiera.pop
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
