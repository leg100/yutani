require 'hiera'

module Yutani
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
