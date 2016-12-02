require 'hiera'
require 'hashie'
require 'logger'
require 'yutani/version'
require 'yutani/config'
require 'yutani/hiera'
require 'yutani/cli'
require 'yutani/dsl_entity'
require 'yutani/reference'
require 'yutani/directory_tree'
require 'yutani/mod'
require 'yutani/stack'
require 'yutani/resource'
require 'yutani/provider'
require 'yutani/utils'

module Yutani

  @stacks = []

  class << self
    attr_accessor :hiera, :stacks, :logger, :entry_path
  end

  class << self
    def logger
      @logger ||= (
        logger = Logger.new(STDOUT)
        logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'INFO'))
        logger
      )
    end

    def stack(name, **scope, &block)
      s = Stack.new(name, **scope, &block)
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

    def build_from_file(file)
      Yutani.entry_path = file

      instance_eval(File.read(file), file)

      unless stacks.empty?
        stacks.each {|s| s.to_fs}
      end
    end
  end
end
