module Yutani
  class Config < Hash
    # Strings rather than symbols are used for compatibility with YAML.
    DEFAULTS = Config[{
      "terraform_dir" => "terraform",
      "hiera_config"  => {
        :backends  => ["yaml"],
        :hierarchy => ["common"],
        :yaml      => {
          :datadir=>"./hiera"
        },
        :logger    => "noop"
      }
    }]
  end
end
