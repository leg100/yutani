module Yutani
  # a stack is a terraform module with
  # additional properties:
  # * module name is hardcoded to 'root'
  # * can only be found at top-level (it's an error if found within another stack/module)
  # * because it's the top-level module, it's immediately evaluated
  # * ability to configure remote state
  class Stack < Mod

    def initialize(**scope, &block)
      super(:root, [], scope, &block)
    end

    def dir_segments
      scope.values.flatten.compact.map{|d| d.to_s.gsub('-', '_') }
    end

    def to_s
      dir_segments.join('_')
    end

    def path
      "root"
    end

    #def path
    #  File.join(dir_segments)
    #end
  end
end
