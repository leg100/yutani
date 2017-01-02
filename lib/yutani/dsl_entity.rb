module Yutani
  class DSLEntity
    def hiera(k)
      Yutani::Hiera.lookup(k)
    end
  end
end
