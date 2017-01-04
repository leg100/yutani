module Yutani
  class Resource
    include Hiera

    attr_accessor :resource_type, :namespace, :fields

    def initialize(resource_type, *namespace, &block)
      @resource_type      = resource_type
      @namespace          = namespace
      @fields             = {}

      Docile.dsl_eval(self, &block) if block_given?
    end

    def resource_name
      @namespace.to_underscored_string
    end

    def to_h
      {
        @resource_type => {
          resource_name => @fields
        }
      }
    end

    def ref(resource_type, *namespace, attr)
      "${%s}" % [resource_type, namespace.to_underscored_string, attr].
        join('.')
    end

    def template(path, **kv)
      Template.new(kv).render(path)
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end

    def method_missing(name, *args, &block)
      if name =~ /ref_(.*)/
        # redirect ref_id, ref_name, etc, to ref()
        ref(*args, $1)
      elsif block_given?
        # handle sub resources, like tags, listener, etc
        sub = SubResource.new
        sub.instance_exec(&block)
        @fields[name] = sub.fields
      else
        @fields[name] = args.first
      end
    end
  end

  class SubResource < Resource
    def initialize
      @fields = {}
    end
  end
end
