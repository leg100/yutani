module Yutani
  class Reference

    def initialize(m='.', t, n, a)
      @m = m
      @t = t
      @n = n
      @a = a
    end

    def path
      @m
    end

    def resource_type
      @t
    end

    def resource_name
      @n
    end

    def attr
      @a
    end

    def find_matching_resources_in_module!(mod)
      resolutions = []
      # we currently support strings for t n and a, and regex
      # for n only
      mod.resources.each do |resource|
        if resource.resource_type == self.resource_type.to_sym
          case self.resource_name
          when Regexp
            if resource.resource_name =~ self.resource_name.to_sym
              resolutions.push(resource)
            end
          when Symbol
            if resource.resource_name == self.resource_name.to_sym
              resolutions.push(resource)
            end
          else
            raise "unsupported class #{self.resource_name.class}"
          end
        end
      end

      resolutions
    end
  end
end
