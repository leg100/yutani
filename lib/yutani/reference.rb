module Yutani
  class Reference

    attr_reader :identifiers, :attr

    def initialize(*identifiers, t, a)
      @identifiers = Set.new(identifiers.map(&:to_sym))
      @t     = t
      @attr  = a
    end

    def resource_type
      @t
    end

    def resource_name
      @scope.join('_')
    end
  end
end
