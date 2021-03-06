begin; require 'pry'; rescue LoadError; end

require 'logger'
require 'docile'

require 'yutani/version'
require 'yutani/config'
require 'yutani/hiera'
require 'yutani/cli'
require 'yutani/stack'
require 'yutani/resource'
require 'yutani/data'
require 'yutani/remote_config'
require 'yutani/provider'
require 'yutani/template'
require 'yutani/utils'

module Yutani
  class << self
    # do we need :logger?
    attr_accessor :hiera, :logger

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
      s.to_fs
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

      # let user use symbols or strings for keys
      yield Yutani::IndifferentHash.new(Hiera.scope)

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
