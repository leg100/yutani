require 'active_support/hash_with_indifferent_access'

module Yutani
  class DSLEntity
    attr_accessor :scope

    def hiera(k)
      # puts "hiera(%s)" % k.inspect
      # hiera expect strings, not symbols
      hiera_scope = @scope.inject({}){|h,(k,v)| h[k.to_s] = v.to_s; h}
      Yutani.logger.debug "hiera scope: %s" % hiera_scope
      v = Yutani.hiera.lookup(k.to_s, nil, hiera_scope)
      # let us use symbols for hash keys
      convert(v)
    end

    private
    def convert(v)
      case v
      when Array
        v.map{|i| convert(i) }
      when Hash
        HashWithIndifferentAccess.new(v)
      else
        v
      end
    end
  end
end
