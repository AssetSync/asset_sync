
require File.dirname(__FILE__) + '/spec_helper'

describe AssetSync::Storage do
  include_context "mock Rails without_yml"

  describe '#upload_files' do
    before(:each) do
      @local_files = ["local_image2.jpg", "local_image1.jpg", "local_stylesheet1.css", "local_stylesheet2.css"]
      @remote_files = ["local_image.jpg", "local_stylesheet1.css"]
      @config = AssetSync::Config.new
    end

    it 'should overwrite all remote files if set to ignore' do
      @config.existing_remote_files = 'ignore'
      storage = AssetSync::Storage.new(@config)
      storage.stub(:local_files).and_return(@local_files)
      File.stub(:file?).and_return(true) # Pretend they all exist

      @local_files.each do |file|
        storage.should_receive(:upload_file).with(file)
      end
      storage.upload_files
    end

    it 'should allow force overwriting of specific files' do
      @config.always_upload = ['local_image.jpg']

      storage = AssetSync::Storage.new(@config)
      storage.stub(:local_files).and_return(@local_files)
      storage.stub(:get_remote_files).and_return(@remote_files)
      File.stub(:file?).and_return(true) # Pretend they all exist

      (@local_files - @remote_files + storage.always_upload_files).each do |file|
        storage.should_receive(:upload_file).with(file)
      end
      storage.upload_files
    end

    it 'should allow to ignore files' do
      @config.ignored_files = ['local_image1.jpg', /local_stylesheet\d\.css/]

      storage = AssetSync::Storage.new(@config)
      storage.stub(:local_files).and_return(@local_files)
      storage.stub(:get_remote_files).and_return(@remote_files)
      File.stub(:file?).and_return(true) # Pretend they all exist

      (@local_files - @remote_files - storage.ignored_files + storage.always_upload_files).each do |file|
        storage.should_receive(:upload_file).with(file)
      end
      storage.upload_files
    end

    it 'should correctly set expire date' do
      local_files = ['file1.jpg', 'file1-1234567890abcdef1234567890abcdef.jpg']
      local_files += ['dir1/dir2/file2.jpg', 'dir1/dir2/file2-1234567890abcdef1234567890abcdef.jpg']
      remote_files = []
      storage = AssetSync::Storage.new(@config)
      storage.stub(:local_files).and_return(local_files)
      storage.stub(:get_remote_files).and_return(remote_files)
      File.stub(:file?).and_return(true)
      File.stub(:open).and_return(nil)

      module Mime
        module Type
          def self.lookup_by_extension(extension)
          end
        end
      end

      def check_file(file)
        case file[:key]
        when 'file1.jpg'
        when 'dir1/dir2/file2.jpg'
          !file.should_not include(:cache_control, :expires)
        when 'file1-1234567890abcdef1234567890abcdef.jpg'
        when 'dir1/dir2/file2-1234567890abcdef1234567890abcdef.jpg'
          file.should include(:cache_control, :expires)
        else
          fail
        end
      end

      files = double()
      local_files.count.times do
        files.should_receive(:create) { |file| check_file(file) }
      end
      storage.stub_chain(:bucket, :files).and_return(files)
      storage.upload_files
    end
  end
end
