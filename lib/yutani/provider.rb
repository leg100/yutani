require 'active_support/hash_with_indifferent_access'

module Yutani
  class Provider < DSLEntity
    attr_accessor :provider_name, :fields

    def initialize(provider_name, **scope, &block)
      @provider_name      = provider_name
      @scope              = HashWithIndifferentAccess.new(scope)
      @fields             = {}

      instance_eval &block if block_given?
    end

    def []=(k,v)
      @fields[k] = v
    end

    def to_h
      {
        @provider_name => @fields
      }
    end

    def method_missing(name, *args, &block)
      if block_given?
        raise StandardError, 
          "provider properties do not accept blocks as parameters"
      else
        @fields[name] = args.first
      end
    end
  end
end
