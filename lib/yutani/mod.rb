require 'json'

module Yutani
  class Mod < DSLEntity
    attr_accessor :name, :resources, :block

    def initialize(name, **scope, &block)
      # set hiera fact 'module_name' to the first identifier
      @name = name
      @resources = {}

      @scope = HashWithIndifferentAccess.new({ 'module_name' => @name }).merge(scope)
      @block = block
    end

    def eval!(scope)
      self.scope.merge!(scope)

      instance_exec(self, &@block)

      @resources.each do |resource_type, rt_hash|
        rt_hash.each do |id, resource|
          resource.scope.merge!(self.scope)
          resource.eval!
          #puts JSON.pretty_generate(resource.to_h)
        end
      end
    end

    def to_h
      { 
        resource: @resources.inject({}){|h_all,(r_type,r)|
          h_all[r_type] = r.inject({}){|h_r, (r_id, r_obj)|
            h_r[r_id] = r_obj.fields
            h_r
          }
          h_all
        }
      }
    end

    def id
      @name
    end

    def path
      "./#{@name.to_s}"
    end

    def resource(resource_type, id, **scope, &block)
      @resources[resource_type] ||= {}
      @resources[resource_type][id] = Resource.new(resource_type, id, scope, &block)
    end
  end
end
