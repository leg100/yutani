require 'hiera'
require 'hashie'
require 'logger'
require 'yutani/version'
require 'yutani/config'
require 'yutani/cli'
require 'yutani/dsl_entity'
require 'yutani/reference'
require 'yutani/directory_tree'
require 'yutani/mod'
require 'yutani/stack'
require 'yutani/resource'

module Yutani

  @stacks = []

  class << self
    attr_accessor :hiera, :stacks, :logger, :entry_path
  end

  @logger = Logger.new(STDERR)
  @logger.level = Logger::INFO

  class << self
    def stack(name, **scope, &block)
      s = Stack.new(name, **scope, &block)
      Yutani.stacks << s
      s
    end

    def configure(config: 'hiera.yaml')
      Yutani.hiera = Hiera.new(:config => config)
    end

    def build_from_file(file)
      Yutani.configure(config: File.join(File.dirname(file), 'hiera.yaml'))
      Yutani.entry_path = file

      instance_eval(File.read(file), file)

      unless stacks.empty?
        stacks.each {|s| s.to_fs}
      end
    end
  end
end
