require 'thor'

module Yutani
  class Cli < Thor
    map '-v' => :version, '--version' => :version

    def self.main(args)
      begin
        Cli.start(args)
      rescue StandardError => e
        Yutani.logger.fatal "#{e.class.name} #{e.message}"

        exit 1
      end
    end

    desc 'version', 'Prints the current version of Yutani'
    def version
      puts Yutani::VERSION
    end
  end
end
