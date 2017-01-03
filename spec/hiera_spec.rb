require 'yutani'

describe Yutani::Hiera do
  before do 
    Yutani::Hiera.hiera('hiera_config_file' => 'spec/hiera.yaml')

    Yutani.scope(a: 1, b: 2) do |s|
      Yutani.scope(c: 3, d: 4) do |s|
        @scope = Yutani::Hiera.scope
        @scope_values = s.values
      end
    end 
  end

  it "should instantiate hiera" do
    expect(Yutani::Hiera.hiera).to be_instance_of ::Hiera
  end

  it "should lookup key in hiera and return value" do
    expect(Yutani::Hiera.lookup(:foo)).to eq 'bar'
  end

  it "should lookup non-existent key in hiera and raise error" do
    expect{ Yutani::Hiera.lookup(:phong) }.to raise_error(
      Yutani::Hiera::NonExistentKeyException)
  end

  it "should build a nested scope" do
    expect(@scope).to eq({
      'a' => 1,
      'b' => 2,
      'c' => 3,
      'd' => 4
    })
  end

  it "should yield scope values" do
    expect(@scope_values).to eq [1,2,3,4]
  end
end
