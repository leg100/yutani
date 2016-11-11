require 'active_support/hash_with_indifferent_access'
require 'docile'

module Yutani
  class Resource < DSLEntity
    attr_accessor :resource_type, :resources, :fields, :mods

    # identifiers is actually only a single id at the moment
    def initialize(resource_type, identifiers, **scope, &block)
      @resource_type      = resource_type
      @identifiers        = identifiers
      @scope              = HashWithIndifferentAccess.new(scope)
      @fields             = {}

      instance_eval &block 
    end

    def []=(k,v)
      @fields[k] = v
    end

    def to_h
      {
        @resource_type => {
          @identifiers => @fields
        }
      }
    end

    def ref(mod_path = [], ref_string)
      if mod_path.empty?
        case ref_string
        when Regexp
          # delay execution until after evaluation phase
          Proc.new{ { mod_path: [], ref: ref_string } }
        when String
          # why a user wouldn't just do this themselves....
          # but it does maintain consistent use of ref()
          "${%s}" % ref_string
        else
          raise "ref() expects a regex or a string"
        end
      else
        # we *have* to defer execution, because we need to locate the module
        # which may not have been evaluated yet
        Proc.new{ { mod_path: mod_path, ref: ref_string } }
      end
    end

#      up, down = find_common_branch(mods, @mods)
#      up.each do |m|
#        m[:outputs] = { "#{resource_type}.#{resource_name}.#{attr}" => "${#{resource_type}.#{resource_name}.#{attr}}" }
#      end
#    end
#
#    def build_mods_hash(tree = {}, mods)
#      unless mods.empty?
#        tree[mods.pop] = { :mods => branch }
#        tree[mods.pop] = build_mods_hash(tree, mods)
#      else
#      end
#    end
#
#    # find_common_branch([:root, :foo, :bar, :wizz], [:root, :foo, :bang, :willip, :bob, :thang])
#    # should output  [[:foo, :wizz], [:foo, :willip, :bob, :thang]]
#    def chop_common_modules(up,down)
#      m1, m2 = up.shift, down.shift
#      
#      if up.shift == down.shift
#        chop_common_modules(up,down)
#      else
#
#      end
#    end
#
#    # find_common_branch([:root, :foo, :bar, :wizz], [:root, :foo, :bang, :willip, :bob, :thang])
#    # should output  [[:foo, :wizz], [:foo, :willip, :bob, :thang]]
#    def find_common_branches(up,down)
#      m1, m2 = up.shift, down.shift
#      
#      if m1 == m2
#        find_common_root(up,down,m1)
#      else
#        [
#          [common,up].flatten.compact,
#          [common,down].flatten.compact
#        ]
#      end
#    end
#
#    #find_common_root([:root, :foo, :bar, :wizz], [:root, :foo, :bang, :willip])
#    #should output :foo
#    def find_common_root(up,down,root=nil)
#      m1, m2 = up.shift, down.shift
#
#      if m1 == m2
#        find_common_root(up,down,m1)
#      else
#        root
#      end
#    end
#
#    def build_mods_hash(branch, mods)
#      unless mods.empty?
#        tree = {}
#        tree[mods.shift] = { :mods => branch }
#        build_mods_hash(tree, mods)
#      end
#    end

    def method_missing(name, *args, &block)
      if block_given?
        sub = SubResource.new
        sub.instance_exec(&block)
        @fields[name] = sub.fields
      else
        @fields[name] = args.first
      end
    end
  end

  class SubResource < Resource 
    attr_reader :fields

    def initialize
      @fields = {}
    end
  end
end
