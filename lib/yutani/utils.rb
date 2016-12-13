require 'hashie'

module Yutani
	class IndifferentHash < Hash
		include Hashie::Extensions::IndifferentAccess
	end

	class DeepMergeHash < Hash
		include Hashie::Extensions::DeepMerge
	end

  module Utils
    class << self
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
