module Yutani
  class Config < Hash
    CONFIG_FILE = '.yutani.yml'

    # Strings rather than symbols are used for compatibility with YAML.
    DEFAULTS = Config[{
      "scripts_dir" => "scripts",
      "includes_dir" => "includes",
      "templates_dir" => "templates",
      "terraform_dir" => "terraform",
      "hiera_config"  => {
        :backends  => ["yaml"],
        :hierarchy => ["common"],
        :yaml      => {
          :datadir=>"hiera"
        },
        :logger    => "noop"
      }
    }]

    class << self
      # Returns a Configuration filled with defaults and fixed for common
      # problems and backwards-compatibility.
      def from(user_config)
        DEFAULTS.merge Config[user_config]
      end
    end

    def read_config_file
      if File.exists? CONFIG_FILE
        YAML.load_file(CONFIG_FILE)
      else
        {}
      end
    end
  end
end
