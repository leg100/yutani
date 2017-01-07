require 'json'
require 'fileutils'

module Yutani
  class Stack
    include Hiera

    attr_accessor :resources, :providers, :outputs, :variables

    def initialize(*namespace, &block)
      @resources     = []
      @data          = []
      @providers     = []
      @remote_config = nil
      @outputs       = {}
      @variables     = {}
      @namespace     = namespace

      Docile.dsl_eval(self, &block) if block_given?
    end

    def name
      @namespace.to_underscored_string
    end

    def resource(resource_type, *namespace, &block)
      @resources <<
        Resource.new(resource_type, *namespace, &block)
    end

    def data(data_type, *namespace, &block)
      @data <<
        Data.new(data_type, *namespace, &block)
    end

    def provider(name, &block)
      @providers <<
        Provider.new(name, &block)
    end

    def remote_config(&block)
      @remote_config = RemoteConfig.new(&block)
    end

    # troposphere-like methods
    def add_resource(resource)
      @resources << resource
    end

    def add_provider(provider)
      @providers << provider
    end

    def inc(&block)
      path = File.join(Yutani.config['includes_dir'], yield)

      eval File.read(path), block.binding, path
    end

    # this generates the contents of *.tf.main
    def to_h
      h = {
        resource: @resources.inject(DeepMergeHash.new){|resources,r|
          resources.deep_merge!(r.to_h)
        },
        data: @data.inject(DeepMergeHash.new){|data,d|
          data.deep_merge!(d.to_h)
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
      File.join(Yutani.config['terraform_dir'], name)
    end

    def to_fs
      FileUtils.mkdir_p(dir_path)
      FileUtils.cd(dir_path) do
        File.open('main.tf.json', 'w+', 0644) do |f|
          f.write pretty_json
        end

        @remote_config.execute! unless @remote_config.nil?
      end
    end
  end
end
