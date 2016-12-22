require 'json'

module Yutani
  class Stack
    attr_accessor :resources, :providers, :outputs, :variables

    def initialize(*namespace, **hiera_scope, &block)
      @resources   = []
      @providers   = []
      @outputs     = {}
      @variables   = {}
      @hiera_scope = hiera_scope
      @namespace   = namespace

      yield self if block_given?
    end

    def name
      @namespace.join('_')
    end

    def scope=(scope)
      @hiera_scope.merge!(scope)
    end

    def resource(resource_type, *namespace, &block)
      @resources <<
        Resource.new(resource_type, *namespace, **@hiera_scope, &block)
    end

    def provider(name, &block)
      @providers <<
        Provider.new(name, &block)
    end

    # troposphere-like methods
    def add_resource(resource)
      @resources << resource
    end

    def add_provider(provider)
      @providers << provider
    end

    # this generates the contents of *.tf.main
    def to_h
      h = { 
        resource: @resources.inject(DeepMergeHash.new){|resources,r|
          resources.deep_merge!(r.to_h)
        },
        provider: @providers.inject(DeepMergeHash.new){|providers,r|
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

    def dir_path
      name
    end

    def tar(filename)
      File.open(filename, 'w+') do |tarball|
        create_dir_tree('./').to_tar(tarball)
      end
    end

    def to_fs(prefix='./terraform')
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
