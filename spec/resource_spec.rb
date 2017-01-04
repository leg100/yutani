require 'yutani'

describe Yutani::Resource do
  before do
    tmpdir = Dir.mktmpdir
    allow(Yutani::Template).to receive(:templates_path) { tmpdir }
    FileUtils.cd tmpdir do
      File.write 'tmpl.erb', "<%= foo %>"
    end

    @resource = Yutani::Resource.new(:rtype, :rname, :'rname-2') do
      propA   'valA'
      subProp {
        propB 'valB'
      }
      propC   ref_id(:rtypeZ, :'rname-with-hyphens', :rmore)
      propD   template('tmpl.erb', foo: 'bar')
    end
  end

  it "should have a name with hyphens converted to underscores" do
    expect(@resource.resource_name).to eq "rname_rname_2"
  end

  # this test covers much of Resource's functionality
  it "spits out a valid hash" do
    expect(@resource.to_h).to eq({
      rtype: {
        'rname_rname_2' => {
          propA: 'valA',
          subProp: {
            propB: 'valB'
          },
          propC: '${rtypeZ.rname_with_hyphens_rmore.id}',
          propD: 'bar'
        }
      }
    })
  end
end
