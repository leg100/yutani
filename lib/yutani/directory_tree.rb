require 'rubygems/package'
require 'fileutils'

module Yutani
  # An abstraction of a real directory tree on disk
  # Permits us to decide later whether this will be written to disk
  # or embedded in a tarball, or sent over scp, etc.
  class DirectoryTree
    File = Struct.new(:path, :permissions, :content)

    attr_reader :files, :prefix

    def initialize(prefix = './')
      @prefix = prefix
      @files = []
    end

    def add_file(path, permissions, content)
      @files << File.new(::File.join(@prefix, path), permissions.to_i, content)
    end

    def to_fs
      @files.each do |f|
        FileUtils.mkdir_p(::File.dirname(f.path))
        ::File.open(f.path, 'w+', f.permissions) do |new_f|
          new_f.write f.content
        end
      end
    end

    def to_tar(io = STDOUT)
      Gem::Package::TarWriter.new(io) do |tar|
        @files.each do |f|
          tar.mkdir(::File.dirname(f.path), '0755')

          tar.add_file_simple(f.path, f.permissions, f.content.bytes.size) do |tar_file|
            tar_file.write f.content
          end
        end
      end
    end
  end
end
