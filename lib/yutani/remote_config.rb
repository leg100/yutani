require 'open3'

module Yutani
  class TerraformCommandError < StandardError; end

  class RemoteConfig
    include Hiera

    def initialize(&block)
      Docile.dsl_eval(self, &block) if block_given?
    end

    def command
      cmds = []
      cmds << "terraform remote config"
      cmds << "-backend=#{@backend}"

      @backend_config.fields.each do |k,v|
        cmds << "-backend-config=\"#{k}=#{v}\""
      end

      cmds << "-pull=false"

      cmds.join(' ')
    end

    def execute!
      _, stderr, ret_code = Open3.capture3(command)

      if ret_code != 0
        raise TerraformCommandError,
          "running the command \"#{command}\" returned error: #{stderr}"
      end
    end

    def backend(backend_type)
      @backend = backend_type
    end

    def backend_config(&block)
      @backend_config = BackendConfig.new(&block)
    end

    class BackendConfig
      attr_reader :fields

      def initialize(&block)
        @fields = {}

        Docile.dsl_eval(self, &block)
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end

      def method_missing(name, *args, &block)
        if block_given?
          raise StandardError,
            "backend_config properties do not accept blocks as parameters"
        else
          @fields[name] = args.first
        end
      end
    end
  end
end
