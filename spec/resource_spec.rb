require 'yutani'

describe Yutani::Resource do
  before do 
    Yutani::Hiera.hiera('hiera_config_file' => 'spec/hiera.yaml')

    @stack = Yutani.stack(:s1) {
      resource(:rtype, :rnameA) {
        propZ hiera(:foo)
      }
    }
    @resource = @stack.resources.last
  end

  it "has a populated resources collection" do
    expect(@stack.resources).to be_instance_of(Array)
  end

  it "should resolve hiera variables correctly" do
    expect(@resource.fields[:propZ]).to eq 'bar'
  end
end
