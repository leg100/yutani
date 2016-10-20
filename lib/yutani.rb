require 'hiera'
require 'yutani/dsl_entity'
require 'yutani/stack'
require 'yutani/mod'
require 'yutani/resource'
require 'rubygems/package'

module Yutani

  @stacks = {}
  @modules = {}

  class << self
    attr_accessor :hiera, :stacks, :modules
  end

  def mod(name, **scope, &block)
    Yutani.modules[name] = Mod.new(name, **scope, &block)
  end

  def stack(name=nil, **scope, &block)
    s = Stack.new(name, **scope, &block)
    Yutani.stacks[s.key] = s
  end

  def configure(config: 'hiera.yaml')
    Yutani.hiera = Hiera.new(:config => config)
  end

  def tar!
    Gem::Package::TarWriter.new(STDOUT) do |tar|
      Yutani.stacks.each do |_, s|
        tar.mkdir s.path, '0755'

        stack_file_path = File.join(s.path, 'main.tf.json')
        stack_file_hash = {}
        stack_file_hash['modules'] = s.modules.inject({}){|h,(name,mod)|
          h[name] = {source: mod.path};h
        }
        stack_file_contents = JSON.pretty_generate(stack_file_hash)
        tar.add_file_simple(stack_file_path, '0644',
                            stack_file_contents.bytes.length) {|f|
          f.write stack_file_contents
        }

        s.modules.each do |_,m|
          tar.mkdir File.join(s.path, m.path), '0755'
          mod_file_contents = JSON.pretty_generate(m.to_h)
          mod_file_path = File.join(s.path, m.path, 'main.tf.json')
          tar.add_file_simple(mod_file_path, '0644', 
                              mod_file_contents.bytes.length) {|f|
            f.write mod_file_contents
          }
        end
      end 
    end
  end
end
