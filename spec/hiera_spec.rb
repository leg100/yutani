require 'yutani'

include Yutani

Yutani.configure(config: 'spec/hiera.yaml')

describe Mod do
  before do 
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
