require 'active_support/hash_with_indifferent_access'

module Yutani
  module Utils
    class << self
      def convert_nested_hash_to_indifferent_access(v)
        case v
        when Array
          v.map{|i| convert_nested_hash_to_indifferent_access(i) }
        when Hash
          HashWithIndifferentAccess.new(v)
        else
          v
        end
      end
    end 
  end
end
