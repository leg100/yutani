require 'yutani'

RSpec.describe 'First Run', :type => :aruba do
  let(:path)          { './bin' }
  let(:hiera_dir)     { 'hiera' }
  let(:terraform_dir) { 'terraform' }
  let(:scripts_dir)   { 'scripts' }
  let(:includes_dir)  { 'includes' }
  let(:common_tier)   { 'hiera/common.yaml' }

  describe 'yutani version' do
    it "prints version" do
      expect(run("yutani -v")).to have_output Yutani::VERSION
    end
  end

  describe 'yutani init' do
    it "initialises config file" do
      run("yutani init")

      expect('.yutani.yml').to be_an_existing_file
    end

    it "creates hiera data directory" do
      run("yutani init")

      expect(hiera_dir).to be_an_existing_directory
    end

    it "creates hiera common tier" do
      run("yutani init")

      expect(common_tier).to be_an_existing_file
    end

    it "creates scripts dir" do
      run("yutani init")

      expect(scripts_dir).to be_an_existing_directory
    end

    it "creates terraform stacks dir" do
      run("yutani init")

      expect(terraform_dir).to be_an_existing_directory
    end

    it "creates includes dir" do
      run("yutani init")

      expect(includes_dir).to be_an_existing_directory
    end
  end

  describe 'yutani build' do
    let(:stacks_rb)     { expand_path('%/stacks.rb') }
    let(:vpc_rb)        { expand_path('%/vpc.rb') }
    let(:common_tier)   { expand_path('%/hiera/common.yaml') }

    before do
      cd ('.') do
        run_simple("yutani init") # run() doesn't work?

        FileUtils.cp stacks_rb,   'scripts/stacks.rb'
        FileUtils.cp vpc_rb,      'includes/vpc.rb'
        FileUtils.cp common_tier, 'hiera/common.yaml'
      end
    end

    it "runs without stderr" do
      run("yutani build")

      expect(last_command_started).to have_output_on_stderr ""
    end

    it "exits with status code zero" do
      run("yutani build")

      expect(last_command_started).to have_exit_status(0)
    end

    it "builds terraform stacks" do
      run("yutani build")

      stack_dir = File.join(terraform_dir, "dev_eu-west-1_vpc")
      main_tf_json = File.join(stack_dir, "main.tf.json")

      expect(stack_dir).to be_an_existing_directory
      expect(main_tf_json).to be_an_existing_file
    end
  end

  describe 'yutani watch' do
    let(:stacks_rb)     { expand_path('%/stacks.rb') }
    let(:vpc_rb)        { expand_path('%/vpc.rb') }
    let(:common_tier)   { expand_path('%/hiera/common.yaml') }

    before do
      cd ('.') do
        run_simple("yutani init") # run() doesn't work?

        FileUtils.cp stacks_rb,   'scripts/stacks.rb'
        FileUtils.cp vpc_rb,      'includes/vpc.rb'
        FileUtils.cp common_tier, 'hiera/common.yaml'

        run("yutani watch", :startup_wait_time => 1, :io_wait_timeout => 1, :exit_timeout => 1)
      end
    end

    # add test to check watch exits cleanly

    it 'should, upon a change to a script, trigger a build' do
      append_to_file('scripts/stacks.rb', "\n")

      sleep 1

      expect(last_command_started.stderr).to  match(/modified/)
    end

    it 'should, upon a change to an include, trigger a build' do
      append_to_file('includes/vpc.rb', "\n")

      sleep 1

      expect(last_command_started.stderr).to  match(/modified/)
    end

    it 'should, upon a ctrl-c, exit cleanly' do
      last_command_started.stop
      expect(last_command_started).to have_exit_status(0)
    end
  end
end
