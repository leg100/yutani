require 'thor'

module Yutani
  class Cli < Thor
    map '-v' => :version, '--version' => :version

    def self.main(args)
      begin
        Cli.start(args)
      rescue StandardError => e
        Yutani.logger.fatal "#{e.class.name} #{e.message}"
        Yutani.logger.fatal Yutani::Cli.format_backtrace(e.backtrace) unless e.backtrace.empty?

        exit 1
      end
    end

    desc 'build', 'Evaluates the given script and creates terraform files'
    def build(script)
      Yutani.build_from_file(script)
    end

    desc 'version', 'Prints the current version of Yutani'
    def version
      puts Yutani::VERSION
    end

    private

    def self.format_backtrace(bt)
      "Backtrace: #{bt.join("\n   from ")}"
    end
  end
end
