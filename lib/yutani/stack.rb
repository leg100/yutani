module Yutani
  class Stack < DSLEntity
    attr_accessor :name, :modules

    def initialize(name=nil, **scope, &block)
      @modules = {}
 
      @scope = HashWithIndifferentAccess.new(scope)
      @scope[:stack_name] = name.to_s unless name.nil?

      instance_exec(self, &block) if block_given?
    end

    def include_mod(name)
      @modules[name] = Yutani.modules[name]
      @modules[name].eval!(self.scope)
    end

    # we'll use scope to uniquely identify the stack 
    def key
      scope
    end

    def dir_segments
      scope.values.flatten.compact.map{|d| d.to_s.gsub('-', '_') }
    end

    def to_s
      dir_segments.join('_')
    end

    def path
      File.join(dir_segments)
    end
  end
end
