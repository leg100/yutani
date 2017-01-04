require 'hashie'

class Array
  def to_underscored_string
    map{|n| n.to_s.gsub('-', '_') }.join('_')
  end
end

module Yutani
	class IndifferentHash < Hash
    include Hashie::Extensions::MergeInitializer
		include Hashie::Extensions::IndifferentAccess
	end

	class DeepMergeHash < Hash
		include Hashie::Extensions::DeepMerge
	end

  module Utils
    class << self
      def convert_symbols_to_strings_in_flat_hash(h)
        h.inject({}) do |h, (k,v)|
          k = k.is_a?(Symbol) ? k.to_s : k
          v = v.is_a?(Symbol) ? v.to_s : v
          h[k] = v
          h
        end
      end

      def convert_nested_hash_to_indifferent_access(v)
        case v
        when Array
          v.map{|i| convert_nested_hash_to_indifferent_access(i) }
        when Hash
          IndifferentHash.new(v)
        else
          v
        end
      end
    end
  end
end
