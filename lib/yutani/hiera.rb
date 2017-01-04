require 'hiera'

# say something about the purpose of this wrapper, for instance
# the way in which yutani maintains a stack of hiera scopes and
# then merges them when a lookup occurs
module Yutani
  module Hiera
    class NonExistentKeyException < StandardError; end

    @scopes = []

    def hiera(k)
      Hiera.lookup(k)
    end

    class << self
      attr_accessor :hiera, :scopes

      def scope
        @scopes.inject({}){|h,scope| h.merge(scope) }
      end

      def push(kv)
        # hiera doesn't accept symbols for scope keys or values
        @scopes.push Yutani::Utils.convert_symbols_to_strings_in_flat_hash(kv)

        Yutani.logger.debug "hiera scope: %s" % scope
      end

      def pop
        @scopes.pop
      end

      def hiera(config_override={})
        @hiera ||= init_hiera(config_override)
      end

      def init_hiera(override={})
        conf = Yutani.config(override)

        # hiera_config_file trumps hiera_config
        ::Hiera.new(config:
          conf.fetch('hiera_config_file', conf['hiera_config'])
        )
      end

      def lookup(k)

        # hiera expects key to be a string
        v = hiera.lookup(k.to_s, nil, scope)

        raise NonExistentKeyException.new(v) if v.nil?

        # if nested hash, let user lookup nested keys with strings or symbols
        Yutani::Utils.convert_nested_hash_to_indifferent_access(v)
      end
    end
  end
end
