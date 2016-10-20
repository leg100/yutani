require 'active_support/hash_with_indifferent_access'

module Yutani
  class Resource < DSLEntity
    attr_accessor :resource_type, :resources, :fields

    def initialize(resource_type, id, **scope, &block)
      @resource_type = resource_type
      @id            = id
      @scope         = HashWithIndifferentAccess.new(scope)
      @block         = block
      @fields        = {}
    end

    def []=(k,v)
      @fields[k] = v
    end

    def eval!
      instance_exec(self, &@block)
    end

    def to_h
      {
        @resource_type => {
          @id => @fields
        }
      }
    end

    def id
      "${module.#{scope[:module_name]}.#{@resource_type}.#{@id}.id}"
    end

    def modules
      Yutani.modules
    end

    def resources
      Yutani.modules[scope[:module_name]].resources
    end

    def method_missing(name, *args, &block)
      @fields[name] = args.first
    end
  end
end
