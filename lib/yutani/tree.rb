module Yutani
  # Singleton class
  class Tree
    @projects  = {}
    @stacks    = {}
    @modules   = {}
    @resources = {}

    class << self
      attr_accessor :projects, :stacks, :modules, :resources
    end
  end
end
