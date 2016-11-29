module Yutani
  class ReferencePath
    def initialize(mods, resource_type, resource_name, attr)
      @mods          = mods
      @resource_type = resource_type
      @resource_name = resource_name
      @attr          = attr
    end

    def interpolation_string(prefix=nil, mods=[])
      resource_params = [@resource_type, @resource_name, @attr]
      if prefix.nil?
        # we're referencing a resource in the local module
        resource_params.join('.')
      else
        resource_params.join('_')
      end
    end

    def shift(prev, curr, nxt)
      traverse(prev.push(curr), nxt.shift, nxt)
    end

    def traverse(prev,
      shift(prev, curr, nxt)
    end
  end
end
