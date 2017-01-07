module Yutani
  class Data
    include Hiera

    attr_accessor :data_type, :namespace, :fields

    def initialize(data_type, *namespace, &block)
      @data_type = data_type
      @namespace = namespace
      @fields    = {}

      Docile.dsl_eval(self, &block) if block_given?
    end

    def data_name
      @namespace.to_underscored_string
    end

    def to_h
      {
        @data_type => {
          data_name => @fields
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
        # handle sub datas, like tags, listener, etc
        sub = SubData.new
        sub.instance_exec(&block)
        @fields[name] = sub.fields
      else
        @fields[name] = args.first
      end
    end
  end

  class SubData < Data
    def initialize
      @fields = {}
    end
  end
end
