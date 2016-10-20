require 'fileutils'
require 'hiera'
require 'singleton'

module Yutani
  class Hiera
    include Singleton

    attr_accessor :scope

    def initialize
      @hiera = ::Hiera.new(:config => "./hiera.yaml")
    end

    def [](key)
      @hiera.lookup(key, nil, @scope)
    end
  end

  class Context
    def output_dir
    end
  end

  class Interpreter
    def initialize
      @fields = {}
      facts = {
        'env' => 'dev',
        'region' => 'eu-west-1'
      }
      @hiera = Hiera.instance
      @hiera.scope = facts
      @facts = @hiera.scope
    end

    def interpret(dsl_file, output_dir)
      @output_dir = output_dir
      instance_eval IO.read(dsl_file)
      Docile.dsl_eval(DSL.new, @hiera, @facts, 
    end

    def stack(*names, &block)
      # do nothing
      puts "called stack() with #{names}"
      puts "called stack() with block #{block}"
      stack = Stack.new(*names, @output_dir)
      @current_stack = stack
      @hiera.scope['stack'] = stack.name
      yield block
    end

    def mod(*names, &block)
      puts "called mod() with #{names}"
      puts "called mod() with block #{block}"
      mod = Mod.new(*names, @current_stack.dir)
      @current_mod = mod
      @hiera.scope['module'] = mod.name
      yield block
    end

    def method_missing(method_name, *args, &block)
      puts "called #{method_name} with #{args} and block #{block}"

			klass_name = method_name.capitalize

      klass = if Object.const_defined? klass_name
                Object.const_get klass_name
              else
                # assume shorthand resource notation
                Object.const_set klass_name, Class.new(Resource)
              end

      if klass == Stack or klass == Mod
        klass.new(ctx, args)
        yield block
      else
        klass.new(ctx, args, block)
      end
    end
  end

  class DSLEntity
    def context
      @context ||= Context.new
    end
  end

  class Resource < DSLEntity
    def initialize(ctx, resource_type, *identifiers, block)
      @context = ctx
      @resource_type = resource_type
      @identifiers = identifiers
      @fields = {}
      @hiera = Hiera.instance
      @facts = @hiera.scope
      puts "facts = #{@facts}"

      instance_eval &block
    end

    def method_missing(method_name, arg)
      puts "called #{method_name} with #{arg}"
      @fields[method_name] = arg
    end

    def self.resolve_references
    end

    def ref(resource_type, attribute, *identifiers)
      # we want to delay the lookup until every resource has been defined
    end

    def to_h
    end
  end

  class Stack < DSLEntity
    attr_reader :dir, :name
    def initialize(name, output_dir)
      stack_names = names.compact.map(&:to_s)
      @name = stack_names[0]
      @dir = File.join(output_dir, stack_names)
      puts "creating directory #{@dir}"
      FileUtils.mkdir_p(@dir)
    end
  end

  class Mod < DSLEntity
    attr_reader :dir, :name
    def initialize(*names, stack_dir)
      mod_names = names.compact.map(&:to_s)
      @name = mod_names[0]
      @dir = File.join(stack_dir, mod_names)
      puts "creating directory #{@dir}"
      FileUtils.mkdir_p(@dir)
    end
  end
end
