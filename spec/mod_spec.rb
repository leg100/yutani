require 'yutani'

describe Yutani::Stack do
  before do 
    @stack = Yutani.stack(a: :x, b: :y) {|a, b|
      provider(:aws) {
        region 'eu-west-1'
      }
      scope(:m1) {
        scope(:m2) {
          scope(:m3) {
            scope(:target_name) {
              resource(:target_type)
              resource(:target_another_type)
            }
            scope(:three){
              resource(:target_type)
            }
          }
        }
        scope(:m4) {|m4|
          scope(:m5) {
            scope(:source_name) {
              resource(:source_type) {
                propX a
                propY m4
                propA ref(:m3, :target_type, :target_attr)
                propB ref(:m3, :three, :target_type, :target_attr)
                propC {
                  subPropC ref(:target_name, :target_another_type, :target_attr)
                }
              }
            }
          }
        }
      }
    }

    resource_id = Set.new(%i[m1 m4 m5 source_name])
    @resource = @stack.resources[:source_type][resource_id]
  end

  it "resolves scope parameters" do
    expect(@resource.fields[:propX]).to eq :x
    expect(@resource.fields[:propY]).to eq :m4
  end

  it "has a provider" do
    aws_provider = @stack.providers.first
    expect(aws_provider.fields[:region]).to eq "eu-west-1"
  end

  it "resolves single references" do
    @stack.resolve_references!

    expect(@resource.fields[:propB]).to eq(
      "${target_type.m1_m2_m3_three.target_attr}"
    )
  end

  it "resolves references to multiple resources" do
    @stack.resolve_references!

    expect(@resource.fields[:propA]).to eq %w[
      ${target_type.m1_m2_m3_target_name.target_attr}
      ${target_type.m1_m2_m3_three.target_attr}
    ]
  end

  it "resolves references wthin blocks within resources" do
    @stack.resolve_references!

    expect(@resource.fields[:propC][:subPropC]).to eq(
      "${target_another_type.m1_m2_m3_target_name.target_attr}"
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
