require 'json'
require 'rubygems/package'
require 'hashie'
require 'pp'
require 'docile'

module Yutani
  # Maps to a terraform module. Named 'mod' to avoid confusion with 
  # ruby 'module'.
  # It can contain :
  # * other modules
  # * resources
  # * other resources (provider, data, etc)
  # * variables
  # * outputs
  # Its block is evaluated depending upon whether it is enclosed within 
  # another module
  # It has the following properties
  # * mandatory name of type symbol
  # * optional scope of type hash
  # * ability to output a tar of its contents
  class Mod < DSLEntity
    attr_accessor :name, :resources, :block, :mods

    def initialize(name, ancestors = [], **scope, &block)
      @name = name
      @ancestors = ancestors

      @scope = scope
      @scope[:module_name] = name

      @mods = []
      @resources = []
      @outputs = []

      instance_eval &block 
    end

    def mod(name, **scope, &block)
      validate_mod_args(name, **scope, &block)

      # if no block or scope, look up reference
      scope, block = lookup_mod_ref(name) if scope.empty? and block.nil?

      merged_scope = @scope.merge(scope)
      ancestors = [@name] + @ancestors

      @mods << Mod.new(name, ancestors, **merged_scope, &block)
    end

    def lookup_mod_ref(name)
      raise "mod #{name} not defined" unless Yutani.modules.key? name
      
      Yutani.modules[name].values
    end

    # if name is not symbol, bad
    # 
    # if name, scope and block are all provided, then good
    # if name only, then good
    # else bad
    def validate_mod_args(name, **scope, &block)
      raise "name #{name} must be a symbol" unless name.is_a? Symbol

      raise "invalid mod reference" unless (name and !scope.empty? and !block.nil?) or 
        (name and scope.empty? and block.nil?)
    end

    class MyHash < Hash
      include Hashie::Extensions::DeepMerge
    end

    def debug
      pp self.to_h
    end

    def to_h
      { 
        path: path,
        modules: @mods.map {|m|
          m.to_h
        },
        resources: @resources.inject(MyHash.new){|resources,r|
          resources.deep_merge(r.to_h)
        }
      }
    end

    def path
      File.join(@ancestors.map(&:to_s), @name.to_s)
    end

    def resource(resource_type, identifiers, **scope, &block)
      merged_scope = @scope.merge(scope)
      @resources << Resource.new(resource_type, identifiers, merged_scope, &block)
    end

    def tar!
      Gem::Package::TarWriter.new(STDOUT) do |tar|
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
