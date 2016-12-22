require 'yutani'

describe Yutani::Stack do
  before do 
    @stack = Yutani.stack(:x, :y) {
      provider(:aws) {
        region 'eu-west-1'
      }
      resource(:t1, :r1a, :r1b)
      resource(:t2, :r2) {
        propX 'a' 
        propA ref_id(:t1, :r1a, :r1b)
        propC {
          subPropC ref_name(:t1, :r1a, :r1b)
        }
      }
    }

    @resource = @stack.resources.last
  end

  it "resolves resource parameter" do
    expect(@resource.fields[:propX]).to eq 'a'
  end

  it "has a provider" do
    aws_provider = @stack.providers.first
    expect(aws_provider.fields[:region]).to eq "eu-west-1"
  end

  it "resolves reference" do
    expect(@resource.fields[:propA]).to eq(
      "${t1.r1a_r1b.id}"
    )
  end

  it "resolves reference wthin block within resource" do
    expect(@resource.fields[:propC][:subPropC]).to eq(
      "${t1.r1a_r1b.name}"
    )
  end

  it "should tar the modules in the stack" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.tar("test.tar")

        expect(File.exists?("test.tar")).to be true

        %x|tar xf test.tar > /dev/null|

        expect(File.exists?('x_y/main.tf.json')).to be true
      end
    end
  end

  it "should write a directory tree out to the filesystem" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.to_fs

        expect(File.exists?('./terraform/x_y/main.tf.json')).to be true
      end
    end
  end

  it "should pass terraform validation" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.to_fs

        FileUtils.cd 'terraform/x_y' do
          expect(system("terraform validate")).to be true
        end
      end
    end
  end
end
