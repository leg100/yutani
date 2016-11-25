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
    attr_accessor :name, :resources, :block, :mods, :params, :outputs, :variables

    def initialize(name, parent, local_scope, parent_scope, &block)
      @name                = name.to_sym

      @scope               = parent_scope.merge(local_scope)
      @scope[:module_name] = name
      @local_scope         = local_scope
      @parent              = parent

      @mods                = []
      @resources           = []
      @outputs             = {}
      @params              = {}
      @variables           = {}

      instance_eval        &block
    end

    def mod(name, **scope, &block)
      # if no block or scope, look up reference
      scope, block = lookup_mod_ref(name) if scope.empty? and block.nil?

      @mods << Mod.new(name, self, scope, @scope, &block)
    end

    def lookup_mod_ref(name)
      raise "mod #{name} not defined" unless Yutani.modules.key? name
      
      Yutani.modules[name].values
    end

    def debug
      resolve_references!(self)
      #pp @mods.unshift(self).map{|m| m.to_h }
    end

    class MyHash < Hash
      include Hashie::Extensions::DeepMerge
    end

    # this generates the contents of *.tf.main
    def to_h
      { 
        module: @mods.inject({}) {|modules,m|
          modules[m.tf_name] = {}
          modules[m.tf_name][:source] = m.dir_path
          modules[m.tf_name].merge! m.params
          modules
        },
        resource: @resources.inject(MyHash.new){|resources,r|
          resources.deep_merge(r.to_h)
        },
        output: @outputs.inject({}){|outputs,(k,v)|
          outputs[k] = { value: v }
          outputs
        },
        variables: @variables.inject({}){|variables,(k,v)|
          variables[k] = {}
          variables
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

    def children
      @mods
    end

    def descendents
      children + children.map{|c| c.descendents}.flatten
    end

    def parent?(mod)
      @parent.name == mod.name
    end

    # given name of mod, return bool
    def child?(mod)
      children.map{|m| m.name }.include? mod.name
    end

    def child_by_name(name)
      children.find{|child| child.name == name.to_sym}
    end

    def path
      File.join(@parent.path, name.to_s)
    end

    # rel_path: relative path to a target mod
    # ret an array of mods tracing that path 
    # sorted from target -> source
    # mods: array of module objects, which after being built is returned
    # path: array of path strings: i.e. [.. .. .. a b c]
    def generate_pathway(mods, path)
      if path.empty?
        return mods.unshift(self)
      elsif path.first == '..'
        path.shift
        @parent.generate_pathway(mods.unshift(self), path)
      else
        child_by_name(path.shift).generate_pathway(mods.unshift(self), path)
      end
    end

    # recursive linked-list function, propagating a variable
    # from a target module to a source module
    def propagate(prev, nxt, *params)
      if prev.empty?
        # we are the source module
        if nxt.empty?
          # src and target in same mod
          "${%s}" % params.join('.')
        else
          if self.child? nxt.first
            # there is no 'composition' mod,
            # just move to nex mod
            nxt.shift.propagate(prev.push(self), nxt, *params)
          elsif self.parent?(nxt.first)
            # we are propagating upward the variable
            self.outputs[params.join('.')] = "${%s}" % params.join('.')
            nxt.shift.propagate(prev.push(self), nxt, *params)
          else
            raise "Propagation error!"
          end
        end
      else
        if nxt.empty?
          # we're the source module
          if self.child? prev.last
            # it's been propagated 'up' to us
            "${module.%s}" % params.join('.')
          elsif self.parent? prev.last
            # it's been propagated 'down' to us
            self.params[params.join('.')] = "${var.%s}" % params.join('.')
            self.variables[params.join('.')] = ""
            "${var.%s}" % params.join('.')
          else
            raise "Propagation error!"
          end
        else
          if self.child? prev.last and self.child? nxt.first
            # we're a 'composition' module; the common ancestor
            # to source and target modules
            params.unshift(prev.last.name)
            # we should probably be setting params on the next module
            # but then what would the next mod do?
            nxt.shift.propagate(prev.push(self), nxt, *params)
          elsif self.child? prev.last and self.parent? nxt.first
            # we're propagating 'upward' the variable
            # towards the common ancestor
            output_value = ['module', params.unshift(prev.last.name)].join('.')
            self.outputs[params.join('.')] = "${%s}" % output_value
            nxt.shift.propagate(prev.push(self), nxt, *params)
          elsif self.parent? prev.last and self.parent? nxt.first
            # we cannot be a child to two parents in a tree!
            raise "Progation error!"
          elsif self.parent? prev.last and self.child? nxt.first
            if prev[-2] and prev.last.child? prev[-2]
              # we are the module after the 'composition' module,
              # on downward slope
              self.params[params.join('.')] = "${module.%s}" % params.join('.')
            else
              # we're propagating 'downward' the variable 
              # towards the source module
              self.params[params.join('.')] = "${var.%s}" % params.join('.')
            end
            self.variables[params.join('.')] = ""
            nxt.shift.propagate(prev.push(self), nxt, *params)
          else
            raise "Propagation error!"
          end
        end
      end
    end

    def resolve_references!
      @resources.each do |r|
        r.resolve_references! do |ref|

          matching_resources = []

          target_path = Pathname.new(ref.path)
          source_path = Pathname.new(self.path)
          relative_path = target_path.relative_path_from(source_path)
          mod_path = generate_pathway([], relative_path.to_s.split('/'))
 
          # lookup matching resources in mod_path.first
          matches = ref.find_matching_resources_in_module!(mod_path.first).map do |res|
            params = [res.type, res.name, ref.attr]
            mod_path.shift.propagate([], mod_path, *params)
          end
          matches.length == 1 ? matches[0] : matches
        end
      end

      children.each do |m|
        m.resolve_references!
      end
    end

    # pretty DSL alias
    def tar!
      create_tar_file!
    end

    def create_tar_file!
      # ideally, this needs to be done automatically as part of to_h
      resolve_references!(self)

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
