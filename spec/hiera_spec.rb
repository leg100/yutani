require 'yutani'

describe Yutani::Stack do
  before do 
    Yutani::Hiera.hiera('hiera_config_file' => 'spec/hiera.yaml')

    @stack = Yutani.stack(:s1) {
      scope(:rnameA) {
        resource(:rtype) {
          propZ hiera(:foo)
        }
      }
    }
    @resource_id = Set.new(%i[rnameA])
  end

  it "should resolve hiera variables correctly" do
    resource = @stack.resources[:rtype][@resource_id]
    expect(resource.fields[:propZ]).to eq 'bar'
  end
end
