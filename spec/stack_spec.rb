require 'yutani'

describe Yutani::Stack do
  before do
    @stack = Yutani.stack(:dev, :'us-east-1') do
      provider(:aws) {
        region 'us-east-1'
      }

      resource(:rtype, :rname, :rname2) do
        propA   'valA'
      end
    end
  end

  it "should have provider" do
    aws_provider = @stack.providers.first
    expect(aws_provider.fields[:region]).to eq "us-east-1"
  end

  it "should have a name with hyphens converted to underscores" do
    expect(@stack.name).to eq "dev_us_east_1"
  end

  it "should spit out a valid hash" do
    expect(@stack.to_h).to eq({
      resource: {
        rtype: {
          'rname_rname2' => {
            propA: 'valA'
          }
        }
      },
      provider: {
        aws: {
          region: 'us-east-1'
        }
      }
    })
  end

  it "should write a directory tree out to the filesystem" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.to_fs

        expect(File.exists?('./terraform/dev_us_east_1/main.tf.json')).to be true
      end
    end
  end

  it "should pass terraform validation" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.to_fs

        FileUtils.cd 'terraform/dev_us_east_1' do
          expect(system("terraform validate")).to be true
        end
      end
    end
  end

  it "should tar the modules in the stack" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.tar("test.tar")

        expect(File.exists?("test.tar")).to be true

        %x|tar xf test.tar > /dev/null|

        expect(File.exists?('dev_us_east_1/main.tf.json')).to be true
      end
    end
  end
end
