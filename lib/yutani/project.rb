require 'json'
require 'pp'
require 'hiera'
require 'active_support/hash_with_indifferent_access'

module Yutani
  class Project < DSLEntity
    attr_accessor :name, :stacks

    class ScopeHash < ActiveSupport::HashWithIndifferentAccess
    end

    def initialize(name, &block)
      @name = name
      @stacks = {}

      @scope = ScopeHash.new({ 'project_name' => name.to_s })
      @project_name = name.to_s
      @block = block
    end

    def parse!
      # this evaluates *all* DSL code
      build_from_block

      # here we're checking everything is where it should be
      # - maybe we should resolve references properly, too
      puts "#{@project_name}/"
      @stacks.each_value do |s|
        puts [@project_name, s.path].join('/')
        s.modules.each_value do |m|
          puts [@project_name, s.path, m.id].join('/')
          puts [@project_name, s.path, m.id, 'main.tf.json'].join('/')
          m.resources.each_value do |r|
            puts JSON.pretty_generate(r.to_h(m.id))
          end
        end
      end
    end
  end
end
