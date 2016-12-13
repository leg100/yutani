require 'active_support/hash_with_indifferent_access'

module Yutani
  class Resource < DSLEntity
    attr_accessor :resource_type, :resources, :fields, :mods, :resource_name

    def initialize(resource_type, resource_name, **scope, &block)
      @resource_type      = resource_type
      @resource_name      = resource_name
      @scope              = HashWithIndifferentAccess.new(scope)
      @fields             = {}

      Docile.dsl_eval(self, &block) if block_given?
    end

    def []=(k,v)
      @fields[k] = v
    end

    def to_h
      {
        @resource_type => {
          @resource_name => @fields
        }
      }
    end

    def ref(*identifiers, t, a)
      Reference.new(*identifiers, t, a)
    end

    def resolve_references!(&block)
      @fields.each do |k,v|
        case v
        when Reference
          @fields[k] = yield v
        when Hash
          v.each do |sub_k,sub_v|
            if sub_v.is_a? Reference
              v[sub_k] = yield sub_v
            end
          end
        else
          next
        end
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end

    def method_missing(name, *args, &block)
      if block_given?
        sub = SubResource.new(scope)
        sub.instance_exec(&block)
        @fields[name] = sub.fields
      else
        @fields[name] = args.first
      end
    end
  end

  class SubResource < Resource 
    def initialize(scope)
      @scope  = scope
      @fields = {}
    end
  end

  ResourceAttribute = Struct.new(:type, :name, :attr)
end
