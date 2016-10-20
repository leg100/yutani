module Yutani
  class Context
    attr_reader :facts, :hiera, :stack, :mod

    def initialize(hiera_config:)
      @scope = {}
      @hiera = Hiera.new(@hiera_config)
    end

    def stack=(stack)
      @stack = stack
      @hiera.scope['stack'] = stack.name
    end

    def mod=(mod)
      @mod = mod
      @hiera.scope['module'] = mod.name
    end

    def scope
      @hiera.scope
    end

    def stack_dir
      @stack.dir
    end

    def current_mod
      @mod.name
    end

    class Hiera
      attr_accessor :scope

      def initialize(facts)
        @hiera = ::Hiera.new(:config => "./hiera.yaml")
        @scope = facts
      end

      def [](key)
        @hiera.lookup(key, nil, @scope)
      end
    end
  end
end
