module Yutani
  class DSLEntity
    attr_accessor :scope

    def hiera(k)
      Yutani::Hiera.lookup(k, @scope)
    end
  end
end
