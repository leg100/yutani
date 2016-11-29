require 'pathname'

module Yutani
  class Reference

    attr_reader :path

    def initialize(path='.', t, n, a)
      @path       = path
      @t          = t
      @n          = n
      @a          = a
    end

    def relative_path(source_mod)
      source_path = Pathname.new(source_mod.path)
      target_path = Pathname.new(@path)
      target_path.relative_path_from(source_path).to_s
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
            if resource.resource_name =~ self.resource_name
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
