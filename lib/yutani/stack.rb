module Yutani
  # a stack is a terraform module with
  # additional properties:
  # * module name is hardcoded to 'root'
  # * can only be found at top-level (it's an error if found within another stack/module)
  # * because it's the top-level module, it's immediately evaluated
  # * ability to configure remote state
  class Stack < Mod

    def initialize(name, **scope, &block)
      super(name, [], scope, {stack_name: name}, &block)
    end

    def mod_path
      "root"
    end
  end
end
