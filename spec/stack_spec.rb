require 'yutani'

describe Yutani::Stack do
  before do
    @yutani_dir = Dir.mktmpdir

    FileUtils.cd(@yutani_dir) do
      @stack = Yutani.stack(:dev, :'us-east-1') do
        provider(:aws) {
          region 'us-east-1'
        }

        remote_config do
          backend :s3
          backend_config {
            bucket "yutani-tf-remote-state"
            key    "us_east_1_dev/terraform.tfstate"
            region "us-east-1"
          }
        end

        resource(:rtype, :rname, :rname2) do
          propA   'valA'
        end
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
    FileUtils.cd @yutani_dir do
      expect(File.exists?('./terraform/dev_us_east_1/main.tf.json')).to be true
    end
  end

  it "should pass terraform validation" do
    FileUtils.cd @yutani_dir do
      FileUtils.cd 'terraform/dev_us_east_1' do
        expect(system("terraform validate")).to be true
      end
    end
  end

  it "should generate a state file" do
    FileUtils.cd @yutani_dir do
      FileUtils.cd 'terraform/dev_us_east_1/.terraform' do
        expect(File.exists?('terraform.tfstate')).to be true
      end
    end
  end

  it "should generate a remote config" do
    FileUtils.cd @yutani_dir do
      FileUtils.cd 'terraform/dev_us_east_1/.terraform' do
        state = JSON.parse(File.read('terraform.tfstate'))
        expect(state.key?('remote')).to be true
      end
    end
  end

  it "should raise error if remote config command fails" do
    FileUtils.cd(@yutani_dir) do
      expect {
        Yutani.stack(:dev, :'us-east-1') do
          remote_config do
            backend :s3
            backend_config {
              phaw "phoawr"
            }
          end
        end
      }.to raise_error(Yutani::TerraformCommandError)
    end
  end
end
