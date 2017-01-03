require 'thor'
require 'json'
require 'pp'
require 'yaml'

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

    desc 'build', 'Evaluates DSL scripts and creates terraform files'
    def build
      scripts_dir = Yutani::Config::DEFAULTS['scripts_dir']

      files = Dir.glob(File.join(scripts_dir, '*.rb'))
      if files.empty?
        raise "Could not find any scripts in '#{scripts_dir}'"
      end

      files.each do |script|
        Yutani.eval_file(script)
      end

      unless Yutani.stacks.empty?
        Yutani.stacks.each {|s| s.to_fs}
      end
    end

    # we need to know these things:
    # * the directory to restrict to watching for changes
    # * the script that build should evaluate 
    # * the glob  - this is hardcoded to *.rb
    desc 'watch', 'Run build upon changes to scripts'
    def watch
      Listen.to(config[:script_dir]) do |_, _, _|
        build(script)
      end.start

      sleep
    end

    desc 'version', 'Prints the current version of Yutani'
    def version
      puts Yutani::VERSION
    end

    desc 'target', 'Generate list of Terraform targets'
    def target(stack_dir, *args)
      files = Dir.glob(File.join(stack_dir, '*.tf.json'))
      if files.empty?
        raise "Could not find *.tf.json files in #{stack_dir}"
      end

      if args.empty?
        raise "No targets specified"
      end

      contents = files.inject({}) do |h, f|
        h.merge!(JSON.parse(File.read(f)))
        h
      end

      targets = contents['resource'].inject({}) do |h,(k,v)|
        h[k] = v.select do |k,v|
          (args - k.split('_')).empty?
        end
        h
      end.reject{|k,v| v.empty? }

      target_flags = targets.inject([]) do |flags, (k,v)|
        flags << v.keys.map do |resource_name|
          "-target " + ["resource", k, resource_name].join('.')
        end
        flags
      end.flatten

      puts target_flags.join(" ")
    end

    # Invoke Terraform CLI command
    def method_missing(name, *args, &block)
      %x/terraform #{name} #{args}/
    end

    desc 'init', 'Initialize with a basic setup'
    def init
      if File.exists? '.yutani.yml'
        Yutani.logger.warn ".yutani.yml already exists, skipping initialization"
      else
        File.open('.yutani.yml', 'w+') do |f|
          f.write Yutani::Config::DEFAULTS.to_yaml(indent: 2)
          puts ".yutani.yml created"
        end

        unless Dir.exists? Yutani::Config::DEFAULTS['terraform_dir']
          FileUtils.mkdir Yutani::Config::DEFAULTS['terraform_dir']
        end

        unless Dir.exists? Yutani::Config::DEFAULTS['scripts_dir']
          FileUtils.mkdir Yutani::Config::DEFAULTS['scripts_dir']
        end

        unless Dir.exists? Yutani::Config::DEFAULTS['includes_dir']
          FileUtils.mkdir Yutani::Config::DEFAULTS['includes_dir']
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
