require 'yutani'

describe Yutani::Mod do
  before do 
    @stack = Yutani.stack :s1 do
      provider :aws do
        region 'eu-west-1'
      end
      mod :m1 do
        mod :m2 do
          mod :m3 do
            resource :target_type, :target_name do
              propX    scope[:stack_name]
              propY    scope[:module_name]
              _timeout 60
            end
            resource :target_type, :target_name_2 do; end
            resource :target_type, :three do; end
          end
        end
        mod :m4 do
          mod :m5 do
            resource :source_type, :source_name do
              propA ref("/root/m1/m2/m3", :target_type, /target/, :target_attr)
              propB ref("/root/m1/m2/m3", :target_type, :three, :target_attr)
            end
          end
        end
      end
    end

    @small_stack = Yutani.stack :s1 do
      mod :m1 do
        resource :target_type, :target_name do
          propX scope[:stack_name]
          propY scope[:module_name]
        end
      end

      mod :m2 do
        resource :source_type, :source_name do
          prop ref('/root/m1', :target_type, :target_name, :target_attr)
        end
      end
    end
  end

  it "stack contains grandchild module" do
    expect(@stack[:m2]).to be_instance_of Yutani::Mod
  end

  it "stack contains five modules" do
    expect(@stack.descendents.length).to eq 5
  end

  it "resolves scope parameters" do
    r = @stack[:m3].resources_hash[:target_type][:target_name]
    expect(r.fields[:propX]).to eq :s1
    expect(r.fields[:propY]).to eq :m3
  end

  it "removes leading underscore from property name" do
    r = @stack[:m3].resources_hash[:target_type][:target_name]
    expect(r.fields[:timeout]).to eq 60
  end

  it "has a provider" do
    aws_provider = @stack.providers.first
    expect(aws_provider.fields[:region]).to eq "eu-west-1"
  end

  it "generates correct pathway" do
    path = @stack[:m5].generate_pathway([], %w[.. .. m2 m3])
    mods = %i(m3 m2 m1 m4 m5).map{|m| @stack[m]}
    expect(path).to eq mods
  end

  it "propagates variables from module to module" do
    hops = %i(m3 m2 m1 m4 m5).map{|m|  @stack[m]}
    ra = Yutani::ResourceAttribute.new(:aws_type, :my_name, :id)
    target = hops.shift
    target.propagate([], hops, [ra.type, ra.name, ra.attr])

    expect(@stack[:m3].outputs).to eq(
      {"aws_type_my_name_id"=>"${aws_type.my_name.id}"})

    expect(@stack[:m2].outputs).to eq(
      {"m3_aws_type_my_name_id"=>"${module.m3.aws_type_my_name_id}"})

    expect(@stack[:m4].params).to eq(
      {"m2_m3_aws_type_my_name_id"=>"${module.m2.m3_aws_type_my_name_id}"})
    expect(@stack[:m4].variables).to eq(
      {"m2_m3_aws_type_my_name_id"=>""})

    expect(@stack[:m5].params).to eq(
      {"m2_m3_aws_type_my_name_id"=>"${var.m2_m3_aws_type_my_name_id}"})
    expect(@stack[:m5].variables).to eq(
      {"m2_m3_aws_type_my_name_id"=>""})
  end

  it "propagates variables from module to module in small stack" do
    hops = [@small_stack[:m1], @small_stack, @small_stack[:m2]]
    ra = Yutani::ResourceAttribute.new(:aws_type, :my_name, :id)
    target = hops.shift
    target.propagate([], hops, [ra.type, ra.name, ra.attr])

    expect(@small_stack[:m1].outputs).to eq(
      {"aws_type_my_name_id"=>"${aws_type.my_name.id}"})

    expect(@small_stack[:m2].params).to eq(
      {"m1_aws_type_my_name_id"=>"${module.m1.aws_type_my_name_id}"})

    expect(@small_stack[:m2].variables).to eq(
      {"m1_aws_type_my_name_id"=>""})
  end

  it "resolves regex references" do
    @stack.resolve_references!
    resource = @stack[:m5].resources_hash[:source_type][:source_name]

    expect(resource.fields[:propA]).to eq %w[
      ${var.m2_m3_target_type_target_name_target_attr}
      ${var.m2_m3_target_type_target_name_2_target_attr}
    ]
  end

  it "resolves string references" do
    @stack.resolve_references!
    resource = @stack[:m5].resources_hash[:source_type][:source_name]

    expect(resource.fields[:propB]).to eq(
      "${var.m2_m3_target_type_three_target_attr}"
    )
  end

  it "should tar the modules in the stack" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.tar("test.tar")

        expect(File.exists?("test.tar")).to be true

        %x|tar xf test.tar > /dev/null|

        expect(File.exists?('s1/m1/m2/m3/main.tf.json')).to be true
        expect(File.exists?('s1/m1/m4/m5/main.tf.json')).to be true
      end
    end
  end

  it "should write a directory tree out to the filesystem" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.to_fs

        expect(File.exists?('./terraform/s1/m1/m2/m3/main.tf.json')).to be true
        expect(File.exists?('./terraform/s1/m1/m4/m5/main.tf.json')).to be true
      end
    end
  end

  it "should pass terraform validation" do
    Dir.mktmpdir do |dir|
      FileUtils.cd dir do
        @stack.to_fs

        FileUtils.cd 'terraform/s1' do
          expect(system("terraform validate")).to be true
        end
      end
    end
  end
end
