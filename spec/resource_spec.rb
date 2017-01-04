require 'yutani'

describe Yutani::Resource do
  before do
    tmpdir = Dir.mktmpdir
    allow(Yutani::Template).to receive(:templates_path) { tmpdir }
    FileUtils.cd tmpdir do
      File.write 'tmpl.erb', "<%= foo %>"
    end

    @resource = Yutani::Resource.new(:rtype, :rname, :rname2) do
      propA   'valA'
      subProp {
        propB 'valB'
      }
      propC   ref_id(:rtypeZ, :rnameZ)
      propD   template('tmpl.erb', foo: 'bar')
    end
  end

  it "has a resource name" do
    expect(@resource.resource_name).to eq "rname_rname2"
  end

  # this test covers much of Resource's functionality
  it "spits out a valid hash" do
    expect(@resource.to_h).to eq({
      rtype: {
        'rname_rname2' => {
          propA: 'valA',
          subProp: {
            propB: 'valB'
          },
          propC: '${rtypeZ.rnameZ.id}',
          propD: 'bar'
        }
      }
    })
  end
end
