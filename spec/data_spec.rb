require 'yutani'

describe Yutani::Data do
  before do
    @data = Yutani::Data.new(:dtype, :dname, :'dname-2') do
      propA   'valA'
      subProp {
        propB 'valB'
      }
    end
  end

  it "should have a name with hyphens converted to underscores" do
    expect(@data.data_name).to eq "dname_dname_2"
  end

  # this test covers much of Data's functionality
  it "spits out a valid hash" do
    expect(@data.to_h).to eq({
      dtype: {
        'dname_dname_2' => {
          propA: 'valA',
          subProp: {
            propB: 'valB'
          }
        }
      }
    })
  end
end
