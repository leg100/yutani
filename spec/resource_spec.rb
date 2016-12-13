require 'yutani'

describe Yutani::Resource do
  before do 
    Yutani::Hiera.hiera('hiera_config_file' => 'spec/hiera.yaml')

    @stack = Yutani.stack(:s1) {
      scope(:rnameA) {
        resource(:rtype) {
          propZ hiera(:foo)
        }
      }
    }
    @resource_id = Set.new(%i[s1 rnameA])
  end

  it "has a populated resources collection" do
    expect(@stack.resources).to be_instance_of(Hash)
    expect(@stack.resources[:rtype]).to be_instance_of(Hash)
    expect(@stack.resources[:rtype].keys.first).to eq @resource_id
  end

  it "should resolve hiera variables correctly" do
    resource = @stack.resources[:rtype][@resource_id]
    expect(resource.fields[:propZ]).to eq 'bar'
  end
end
