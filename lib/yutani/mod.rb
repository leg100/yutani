require 'json'
require 'hashie'
require 'pp'

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
    attr_accessor :name, :resources, :providers, :block, :mods, :params, :outputs, :variables

    def initialize(name, parent, local_scope, parent_scope, &block)
      @name                = name.to_sym

      @scope               = parent_scope.merge(local_scope)
      @scope[:module_name] = name
      @local_scope         = local_scope
      @parent              = parent

      @mods                = []
      @resources           = []
      @providers           = []
      @outputs             = {}
      @params              = {}
      @variables           = {}

      instance_eval        &block
    end

    def mod(name, **scope, &block)

      @mods << Mod.new(name, self, scope, @scope, &block)
    end

    def source(path)
      absolute_path = File.expand_path(path, File.dirname(Yutani.entry_path))
      contents = File.read absolute_path

      instance_eval contents, path
    end

    def resources_hash
      @resources.inject({}) do |r_hash, r|
        r_hash[r.resource_type] ||= {}
        r_hash[r.resource_type][r.resource_name] = r 
        r_hash
      end
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
      h = { 
        module: @mods.inject({}) {|modules,m|
          modules[m.tf_name] = {}
          modules[m.tf_name][:source] = m.dir_path
          modules[m.tf_name].merge! m.params
          modules
        },
        resource: @resources.inject(MyHash.new){|resources,r|
          resources.deep_merge(r.to_h)
        },
        provider: @providers.inject(MyHash.new){|providers,r|
          providers.deep_merge(r.to_h)
        },
        output: @outputs.inject({}){|outputs,(k,v)|
          outputs[k] = { value: v }
          outputs
        },
        variable: @variables.inject({}){|variables,(k,v)|
          variables[k] = {}
          variables
        }
      }

      # terraform doesn't like empty output and variable collections
      h.delete_if {|_,v| v.empty? }
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

    def provider(provider_name, **scope, &block)
      merged_scope = @scope.merge(scope)
      @providers <<
        Provider.new(provider_name, merged_scope, &block)
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

    class InvalidReferencePathException < StandardError; end

    # rel_path: relative path to a target mod
    # ret an array of mods tracing that path 
    # sorted from target -> source
    # mods: array of module objects, which after being built is returned
    # path: array of path strings: i.e. [.. .. .. a b c]

    def generate_pathway(mods, path)
      curr = path.shift

      case curr
      when /[a-z]+/
        child = child_by_name(curr)
        if child.nil?
          raise InvalidReferencePathException, "no such module #{curr}" 
        else
          child.generate_pathway(mods.unshift(self), path)
        end
      when '..'
        if @parent.nil?
          raise InvalidReferencePathException, "no such module #{curr}" 
        else
          @parent.generate_pathway(mods.unshift(self), path)
        end
      when nil
        return mods.unshift(self)
      else
        raise InvalidReferencePathException, "invalid path component: #{curr}" 
      end
    end

    # recursive linked-list function, propagating a variable
    # from a target module to a source module
    # seed var with array of [type,name,attr]
    def propagate(prev, nxt, var)
      if prev.empty?
        # we are the source module
        if nxt.empty?
          # src and target in same mod
          "${%s}" % var.join('.')
        else
          if self.child? nxt.first
            # there is no 'composition' mod,
            new_var = [self.name, var].flatten
            nxt.first.params[new_var.join('_')] = "${%s}" % new_var.join('.')
            nxt.first.variables[new_var] = ''

            nxt.shift.propagate(prev.push(self), nxt, var)
          elsif self.parent?(nxt.first)
            # we are propagating upward the variable
            self.outputs[var.join('_')] = "${%s}" % var.join('.')
            nxt.shift.propagate(prev.push(self), nxt, var.join('_'))
          else
            raise "Propagation error!"
          end
        end
      else
        if nxt.empty?
          # we're the source module
          if self.child? prev.last
            # it's been propagated 'up' to us
            "${module.%s.%s}" % [prev.last.name, var]
          elsif self.parent? prev.last
            # it's been propagated 'down' to us
            "${var.%s}" % var
          else
            raise "Propagation error!"
          end
        else
          if self.child? prev.last and self.child? nxt.first
            # we're a 'composition' module; the common ancestor
            # to source and target modules
            new_var = [prev.last.name, var]
            nxt.first.params[new_var.join('_')] = "${module.%s.%s}" % new_var
            nxt.first.variables[new_var.join('_')] = ""

            nxt.shift.propagate(prev.push(self), nxt, new_var.join('_'))
          elsif self.child? prev.last and self.parent? nxt.first
            # we're propagating 'upward' the variable
            # towards the common ancestor
            
            new_var = [prev.last.name, var]
            self.outputs[new_var.join('_')] = "${module.%s.%s}" % new_var

            nxt.shift.propagate(prev.push(self), nxt, new_var.join('_'))
          elsif self.parent? prev.last and self.parent? nxt.first
            # we cannot be a child to two parents in a tree!
            raise "Progation error!"
          elsif self.parent? prev.last and self.child? nxt.first
            nxt.first.params[var] = "${var.%s}" % var
            nxt.first.variables[var] = ""

            nxt.shift.propagate(prev.push(self), nxt, var)
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

          path_components = ref.relative_path(self).split('/')
          mod_path = generate_pathway([], path_components)
          target_mod = mod_path.shift
 
          # lookup matching resources in mod_path.first
          matches = ref.find_matching_resources_in_module!(target_mod)

          if matches.empty?
            raise ReferenceException, 
              "no matching resources found in mod #{target_mod.name}"
          end

          interpolation_strings = matches.map do |res|
            ra = ResourceAttribute.new(res.resource_type, res.resource_name, ref.attr)
            # clone mod_path, because propagate() will alter it
            target_mod.propagate([], mod_path.clone, [ra.type, ra.name, ra.attr])
          end
          interpolation_strings.length == 1 ? interpolation_strings[0] : 
            interpolation_strings
        end
      end

      children.each do |m|
        m.resolve_references!
      end
    end

    def tar(filename)
      # ideally, this needs to be done automatically as part of to_h
      resolve_references!

      File.open(filename, 'w+') do |tarball|
        create_dir_tree('./').to_tar(tarball)
      end
    end

    def to_fs(prefix='./terraform')
      # ideally, this needs to be done automatically as part of to_h
      resolve_references!

      create_dir_tree(prefix).to_fs
    end

    def create_dir_tree(prefix)
      dir_tree(DirectoryTree.new(prefix), '')
    end

    def dir_tree(dt, prefix)
      full_dir_path = File.join(prefix, self.dir_path)
      main_tf_path = File.join(full_dir_path, 'main.tf.json')

      dt.add_file(
        main_tf_path,
        0644,
        self.pretty_json
      )

      mods.each do |m|
        m.dir_tree(dt, full_dir_path)
      end

      dt
    end
  end
end
