require 'yutani'
require 'pp'

include Yutani

describe Mod do
  before do 
    @stack = stack :s1 do
      mod :m1 do
        mod :m2 do
          mod :m3 do
            resource :target_type, :target_name do
            end
          end
        end
        mod :m4 do
          mod :m5 do
            resource :source_type, :source_name do
              prop ref("/root/m1/m2/m3", :target_type, :target_name, :target_attr)
            end
          end
        end
      end
    end
  end

  it "stack contains grandchild module" do
    expect(@stack[:m2]).to be_instance_of Mod
  end

  it "stack contains five modules" do
    expect(@stack.descendents.length).to eq 5
  end

  it "generates correct pathway" do
    path = @stack[:m5].generate_pathway([], %w[.. .. m2 m3])
    mods = %i(m3 m2 m1 m4 m5).map{|m| @stack[m]}
    expect(path).to eq mods
  end

  it "propagates variables from module to module" do
    hops = %i(m3 m2 m1 m4 m5).map{|m|  @stack[m]}
    hops.shift.propagate([], hops, :aws_type, :my_name, :id)
    expect(@stack[:m3].outputs).to eq(
      {"aws_type.my_name.id"=>"${aws_type.my_name.id}"})

    expect(@stack[:m2].outputs).to eq(
      {"m3.aws_type.my_name.id"=>"${module.m3.aws_type.my_name.id}"})

    expect(@stack[:m4].params).to eq(
      {"m2.m3.aws_type.my_name.id"=>"${module.m2.m3.aws_type.my_name.id}"})
    expect(@stack[:m4].variables).to eq(
      {"m2.m3.aws_type.my_name.id"=>""})

    expect(@stack[:m5].params).to eq(
      {"m2.m3.aws_type.my_name.id"=>"${var.m2.m3.aws_type.my_name.id}"})
    expect(@stack[:m5].variables).to eq(
      {"m2.m3.aws_type.my_name.id"=>""})
  end

  it "resolves references" do
    @stack.resolve_references!
    resource = @stack[:m5].resources.find{|r| r.type == :source_type and r.name == :source_name}
    expect(resource.fields[:prop]).to eq "${var.m2.m3.target_type.target_name.target_attr}"
  end
end
