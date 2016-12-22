require 'yutani'

describe Yutani::Stack do
  before do 
    Yutani::Hiera.hiera('hiera_config_file' => 'spec/hiera.yaml')

    @stack = Yutani.stack(:s1) {
      resource(:rtype, :n1) {
        propZ hiera(:foo)
      }
    }
    @resource = @stack.resources.first
  end

  it "should resolve hiera variables correctly" do
    expect(@resource.fields[:propZ]).to eq 'bar'
  end
end
