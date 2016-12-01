RSpec.describe 'First Run', :type => :aruba do
  let(:path) { './bin' }

  it "prints version" do 
    expect(run("yutani -v")).to have_output '0.0.2'
  end

  it "initialises config file" do 
    run("yutani init")

    expect('.yutani.yml').to be_an_existing_file
  end
end
