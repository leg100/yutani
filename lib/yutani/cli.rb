require 'thor'
require 'json'
require 'pp'
require 'yaml'
require 'listen'

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
      scripts_dir = Yutani.config['scripts_dir']

      files = Dir.glob(File.join(scripts_dir, '*.rb'))
      if files.empty?
        raise "Could not find any scripts in '#{scripts_dir}'"
      end

      files.each do |script|
        Yutani.eval_file(script)
      end
    end

    # we need to know these things:
    # * the directory to restrict to watching for changes
    # * the script that build should evaluate
    # * the glob  - this is hardcoded to *.rb
    desc 'watch', 'Run build upon changes to scripts'
    def watch
      Listen.to(
        Yutani.config['scripts_dir'],
        Yutani.config['includes_dir'],
        Yutani.config['templates_dir']
      ) do |m, a, d|

        Yutani.logger.info "Re-build triggered: #{m} modified" unless m.empty?
        Yutani.logger.info "Re-build triggered: #{a} added" unless a.empty?
        Yutani.logger.info "Re-build triggered: #{d} deleted" unless d.empty?

        begin
          build
        rescue Exception => e
          Yutani.logger.error "#{e.class.name} #{e.message}"
          #Yutani.logger.error Yutani::Cli.format_backtrace(e.backtrace) unless e.backtrace.empty?
        else
          Yutani.logger.info "Re-build finished successfully"
        end
      end.start

      # exit cleanly upon Ctrl-C
      %w[INT TERM USR1].each do |sig|
        Signal.trap(sig) do
          exit
        end
      end

      sleep
    end

    desc 'version', 'Prints the current version of Yutani'
    def version
      puts Yutani::VERSION
    end

    %w(plan apply destroy).each do |tf_cmd|
      desc tf_cmd, "Run terraform #{tf_cmd} with wildcard targets"
      define_method tf_cmd do |*args|
        # we only support json files
        files = Dir.glob('*.tf.json')
        if files.empty?
          raise "Could not find any *.tf.json files"
        end

        # merge contents of *.tf.json files into one hash
        contents = files.inject({}) do |h, f|
          h.merge!(JSON.parse(File.read(f)))
          h
        end

        new_args = []
        expand_target_wildcard_args(new_args, args, contents)

        Yutani::Utils.run_tf_command(tf_cmd, new_args)
      end
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

        unless Dir.exists? Yutani::Config::DEFAULTS['templates_dir']
          FileUtils.mkdir Yutani::Config::DEFAULTS['templates_dir']
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

    # horror show, in dire need of a succint algorithm
    def expand_target_wildcard_args(new_args, args, contents)
      flag = args.shift

      if flag == '-target'
        target_val = args.shift

        if target_val.nil?
          raise "-target arg missing corresponding target resource"
        end

        # if no wildcard found, then pass through unaltered
        if target_val !~ /\*/
          new_args << '-target'
          new_args << target_val
          expand_target_wildcard_args(new_args, args, contents)
        end

        target_regex = Regexp.new('^' + target_val.gsub(/\*/, '.*') + '$')

        tf_targets = []
        contents['resource'].each do |resource_type,v|
          v.each do |resource_name,_|
            if "#{resource_type}.#{resource_name}" =~ target_regex
              tf_targets << "#{resource_type}.#{resource_name}"
            end
          end
        end

        if tf_targets.empty?
          # we didn't find any matches, so pass through unaltered and
          # let TF throw error
          new_args << '-target'
          new_args << target_val
        else
          tf_targets.each do |target|
            new_args << '-target'
            new_args << target
          end
        end
      elsif flag.nil?
        return
      else
        new_args.push flag
      end

      expand_target_wildcard_args(new_args, args, contents)
    end

    def self.format_backtrace(bt)
      "Backtrace: #{bt.join("\n   from ")}"
    end
  end
end
