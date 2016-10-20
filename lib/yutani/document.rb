require 'fileutils'

module Yutani
  class Document < Block
    def initialize
      puts "creating new doc"
      @ctx = Context.new
    end

    def stack(name, *subdirs, &block)
      Stack.new(@ctx, name, subdirs, &block)
    end
    #
    # assume shorthand resource notation
    def method_missing(method_name, *args, &block)
      puts "method_missing in Document"
    end
  end
end
