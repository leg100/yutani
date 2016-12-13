require 'json'
require 'set'
require 'hashie'
require 'pry'

module Yutani
  # a stack is a terraform module with
  # additional properties:
  # * module name is hardcoded to 'root'
  # * can only be found at top-level (it's an error if found within another stack/module)
  # * because it's the top-level module, it's immediately evaluated
  # * ability to configure remote state
  class Stack
    attr_accessor :name, :resources, :providers, :outputs, :variables

    def initialize(*identifiers, **scope, &block)
      @resources         = Hash.new{|h,k| h[k] = {}}
      @providers         = []
      @outputs           = {}
      @variables         = {}
      @identifiers       = Set.new(identifiers.map(&:to_sym) + scope.values.map(&:to_sym))
      @scope             = scope

      Docile.dsl_eval(self, *@identifiers.to_a, &block)
    end

    def name
      @identifiers.to_a.join('_')
    end

    def inc(&block)
      path = yield
      eval File.read(path), block.binding, path
    end

    def scope(*identifiers, **scope, &block)
      identifiers          += scope.values

      ancestor_scope       = @scope
      ancestor_identifiers = @identifiers

      @scope.merge!(scope)
      @identifiers += identifiers.map(&:to_sym)

      yield *identifiers

      @scope               = ancestor_scope
      @identifiers         = ancestor_identifiers
    end

    def resource(resource_type, &block)
      @resources[resource_type][@identifiers] =
        Resource.new(resource_type, name, @scope, &block)
    end

    def provider(provider_name, &block)
      @providers << Provider.new(provider_name, @scope, &block)
    end

    class MyHash < Hash
      include Hashie::Extensions::DeepMerge
    end

    # this generates the contents of *.tf.main
    def to_h
      h = { 
        resource: @resources.inject(MyHash.new){|resources,(_, r_id_hash)|
          r_id_hash.values.each {|r| resources.deep_merge!(r.to_h) }
          resources
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

    def pretty_json
      JSON.pretty_generate(to_h)
    end

    def resources_array
      # iron out nested hash into an array.
      # don't flatten recursively! otherwise it does
      # strange things to hashes
      @resources.values.map(&:values).flatten(1)
    end

    class ReferenceException < StandardError; end

    def resolve_references!
      resources_array.each do |r|
        r.resolve_references! do |ref|

          matches = @resources[ref.resource_type].select do |identifiers, r|
            # is the references' identifiers a subset of the resources' identifiers?
            ref.identifiers.subset? identifiers
            # if so, return the resource objects
          end.values

          if matches.empty?
            binding.pry
            raise ReferenceException, 
              "no matching resources found with dimensions #{ref.identifiers.to_a.join(',')}" +
                " and type #{ref.resource_type}"
          end

          interpolation_strings = matches.map do |res|
            "${%s}" % [res.resource_type, res.resource_name, ref.attr].join('.')
          end

          # this needs working on - because one result is returned, doesn't necessarily
          # mean the user wasn't expecting it to be encapsulated in an array.
          # (TF expects certain property values to be arrays)
          interpolation_strings.length == 1 ? interpolation_strings[0] : 
            interpolation_strings
        end
      end
    end

    def dir_path
      name
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

      dt
    end
  end
end
