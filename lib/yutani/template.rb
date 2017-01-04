require 'erb'

module Yutani
  class TemplateNotFoundError < StandardError; end

  # an openstruct is useful because it lets us take a hash
  # and turn its k/v's into local variables inside the tmpl
  class Template < OpenStruct
    include Hiera

    class << self
      def templates_path
        Yutani.config['templates_dir']
      end
    end

    def render(path)
      full_path = File.join(Template.templates_path, path)

      unless File.exists?(full_path)
        raise TemplateNotFoundError, full_path
      end

      ERB.new(File.read(full_path)).result binding
    end
  end
end
