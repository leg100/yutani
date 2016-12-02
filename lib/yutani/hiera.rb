module Yutani
  module Hiera
    class << self
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

      def lookup(k, scope)
        # hiera expects strings, not symbols
        hiera_scope = scope.inject({}){|h,(k,v)| h[k.to_s] = v.to_s; h}
        Yutani.logger.debug "hiera scope: %s" % hiera_scope

        v = Yutani::Hiera.hiera.lookup(k.to_s, nil, hiera_scope)
        Yutani.logger.warn "hiera couldn't find value for key #{k}" if v.nil?

        # let us use symbols for hash keys
        Yutani::Utils.convert_nested_hash_to_indifferent_access(v)
      end
    end
  end
end
