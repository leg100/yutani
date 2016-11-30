RSpec.describe 'First Run', :type => :aruba do
  let(:path) { './bin' }

  it "prints version" do 
    expect(run("yutani -v")).to have_output '0.0.2'
  end
end
