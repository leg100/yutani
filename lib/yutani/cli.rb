require 'thor'
require 'yaml'
require 'guard'
require 'guard/commander'

module Yutani
  class Cli < Thor
    map '-v' => :version, '--version' => :version
    map '--hiera-config-file' => :hiera_config_file

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
      Yutani.eval_file(script)

      unless Yutani.stacks.empty?
        Yutani.stacks.each {|s| s.to_fs}
      end
    end

    # we need to know these things:
    # * the directory to restrict to watching for changes
    # * the script that build should evaluate 
    # * the glob  - this is hardcoded to *.rb
    desc 'watch', 'Run build upon changes to files/directories'
    def watch(script, script_dir)
			guardfile = <<-EOF
run_build = proc do
  system("yutani build #{script}")
end

guard :yield, { :run_on_modifications => run_build } do
  watch(%r|^.*\.rb$|)
end
EOF
      Guard.start(guardfile_contents: guardfile, watchdir: script_dir, debug: true)
    end

    desc 'version', 'Prints the current version of Yutani'
    def version
      puts Yutani::VERSION
    end

    desc 'init', 'Initialize with a basic setup'
    def init
      if File.exists? '.yutani.yml'
        puts ".yutani.yml already exists, skipping initialization"
      else
        File.open('.yutani.yml', 'w+') do |f|
          f.write Yutani::Config::DEFAULTS.to_yaml(indent: 2)
          puts ".yutani.yml created"
        end

        hiera_dir = Yutani::Config::DEFAULTS['hiera_config'][:yaml][:datadir]
        FileUtils.mkdir hiera_dir unless Dir.exists? hiera_dir

        common_yml = File.join(hiera_dir, 'common.yaml')
        unless File.exists? common_yml
          File.new(common_yml, 'w+')
          puts "#{common_yml} created"
        end
      end
    end

    private

    def self.format_backtrace(bt)
      "Backtrace: #{bt.join("\n   from ")}"
    end
  end
end
