require 'yutani'
require 'tmpdir'
require 'tempfile'
require 'rubygems/package'

include Yutani

describe DirectoryTree do
  before do 
    @paths = %w[
      a.rb
      a/b.rb
      a/b/c.rb
    ]

    Dir.mktmpdir do |prefix|
      @dt = DirectoryTree.new(prefix) 

      @paths.each{|p| @dt.add_file(p, 0644, '{}')}
    end
  end

  it "can create files and directories" do
    # create tmp dir and set as prefix
    @dt.to_fs

    FileUtils.cd @dt.prefix do
      expect(File.exists?("a.rb")).to be true
      expect(File.exists?("a/b.rb")).to be true
      expect(File.exists?("a/b/c.rb")).to be true
    end
  end

  it "can create a tarball" do
    Dir.mktmpdir do |dir|
      Tempfile.open do |tarball|
        @dt.to_tar(tarball)

        FileUtils.cd dir do
          %x|tar xf #{tarball.path} > /dev/null|

          FileUtils.cd @dt.prefix.sub(/^\//, '') do # remove leading slash
            expect(File.exists?("a.rb")).to be true
            expect(File.exists?("a/b.rb")).to be true
            expect(File.exists?("a/b/c.rb")).to be true
          end
        end
      end
    end
  end
end
