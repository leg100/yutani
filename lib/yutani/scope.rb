module Yutani
  class Scope
    def initialize(stack:, hiera_scope:, dimensions:, yielding:, &block)
      @stack             = stack
      @hiera_scope       = hiera_scope
      @dimensions        = dimensions

      Docile.dsl_eval(self, *yielding, &block)
    end

    def scope(*identifiers, **hiera_scope, &block)
      dimensions = @dimensions.
        union(identifiers.map(&:to_sym)).
        union(hiera_scope.values.map(&:to_sym))

      Scope.new(stack:       @stack,
                hiera_scope: @hiera_scope.merge(hiera_scope),
                dimensions:  dimensions,
                yielding:    identifiers + hiera_scope.values,
                &block)
    end

    def inc(&block)
      path = yield
      eval File.read(path), block.binding, path
    end

    def resource(resource_type, *resource_names, **hiera_scope, &block)
      dimensions = @dimensions.
        union(resource_names.map(&:to_sym)).
        union(hiera_scope.values.map(&:to_sym))

      hiera_scope = @hiera_scope.merge(hiera_scope)
	
      @stack.resources[resource_type][dimensions] =
        Resource.new(resource_type, dimensions, hiera_scope, &block)
    end

    def provider(provider_name, &block)
      @stack.providers << Provider.new(provider_name, @hiera_scope, &block)
    end
  end
end
