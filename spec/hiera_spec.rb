require 'yutani'

describe Yutani::Mod do
  before do 
    Yutani::Hiera.hiera('hiera_config_file' => 'spec/hiera.yaml')

    @stack = Yutani.stack :s1 do
      resource :rtype, :rnameA do
        propZ hiera(:foo)
      end
    end
  end

  it "should resolve hiera variables correctly" do
    resource = @stack.resources_hash[:rtype][:rnameA]
    expect(resource.fields[:propZ]).to eq 'bar'
  end
end
