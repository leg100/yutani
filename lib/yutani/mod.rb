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
    attr_accessor :name, :resources, :block, :mods, :params

    def initialize(name, ancestors = [], local_scope, parent_scope, &block)
      @name                = name
      @ancestors           = ancestors

      @scope               = parent_scope.merge(local_scope)
      @scope[:module_name] = name
      @local_scope         = local_scope

      @mods                = []
      @resources           = []
      @outputs             = {}
      @params              = {}

      instance_eval        &block
    end

    def mod(name, **scope, &block)
      validate_mod_args(name, **scope, &block)

      # if no block or scope, look up reference
      scope, block = lookup_mod_ref(name) if scope.empty? and block.nil?

      ancestors = [@name] + @ancestors

      @mods << Mod.new(name, ancestors, scope, @scope, &block)
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
      pp @mods.unshift(self).map{|m| m.to_h }
    end

    # this generates the contents of *.tf.main
    def to_h
      { 
        module: @mods.inject({}) {|modules,m|
          modules[m.tf_name] = {}
          modules[m.tf_name][:source] = m.dir_path
          modules[m.tf_name] = m.params
          modules
        },
        resource: @resources.inject(MyHash.new){|resources,r|
          resources.deep_merge(r.to_h)
        },
        outputs: @outputs.inject({}){|outputs,(k,v)|
          outputs[k] = { value: v }
          outputs
        }
      }
    end

    def tf_name
      dirs = @local_scope.values.map{|v| v.to_s.gsub('-', '_') }
      dirs.unshift(name)
      dirs.join('_')
    end

    def dir_path
      tf_name
    end

    def resource(resource_type, identifiers, **scope, &block)
      merged_scope = @scope.merge(scope)
      @resources <<
        Resource.new(resource_type, identifiers, merged_scope, &block)
    end

    def pretty_json
      JSON.pretty_generate(to_h)
    end

    # pretty DSL alias
    def tar!
      create_tar_file!
    end

    def create_tar_file!
      Gem::Package::TarWriter.new(STDOUT) do |tar|
        tar_files('/', tar)
      end
    end

    def tar_files(prefix, io)
      full_dir_path = File.join(prefix, dir_path)
      main_tf_path = File.join(full_dir_path, 'main.tf.json')

      io.mkdir full_dir_path, '0755'
      io.add_file_simple(main_tf_path, '0644', pretty_json.bytes.size) {|f|
        f.write pretty_json
      }

      mods.each do |m|
        m.tar_files(full_dir_path, io)
      end
    end
  end
end
