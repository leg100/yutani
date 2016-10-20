require 'docile'

module Yutani
  class Block
    def build_from_block(*args, &block)
      Docile.dsl_eval(self, *args, &block) if block_given?
      self
    end

    def stack(a, *b, &block)
      puts "stack()"
    end

    def build_from_file(facts, hiera, file)
      build_from_block(facts, hiera) do
        instance_exec(facts, hiera) do |facts, hiera|
          instance_eval File.read(file), file
        end
      end
      self
    end
    
    def hiera
      @ctx.hiera
    end
    
    def facts
      @ctx.facts
    end
  end
end
