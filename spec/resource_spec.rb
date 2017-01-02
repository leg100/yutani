require 'yutani'

describe Yutani::Resource do
  before do 
    @resource = Yutani::Resource.new(:rtype, :rname, :rname2) do
      propA   'valA'
      subProp {
        propB 'valB'
      }
      propC   ref_id(:rtypeZ, :rnameZ)
    end
  end

  it "has a resource name" do
    expect(@resource.resource_name).to eq "rname_rname2"
  end

  it "spits out a valid hash" do
    expect(@resource.to_h).to eq({
      rtype: {
        'rname_rname2' => {
          propA: 'valA',
          subProp: {
            propB: 'valB'
          },
          propC: '${rtypeZ.rnameZ.id}'
        }
      }
    })
  end
end
