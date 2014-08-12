require File.dirname(__FILE__) + '/../spec_helper'

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
      allow(storage).to receive(:local_files).and_return(@local_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      @local_files.each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end
      storage.upload_files
    end

    it 'should allow force overwriting of specific files' do
      @config.always_upload = ['local_image.jpg']

      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      (@local_files - @remote_files + storage.always_upload_files).each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end
      storage.upload_files
    end

    it 'should allow to ignore files' do
      @config.ignored_files = ['local_image1.jpg', /local_stylesheet\d\.css/]

      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      (@local_files - @remote_files - storage.ignored_files + storage.always_upload_files).each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end
      storage.upload_files
    end

    it 'should upload updated non-fingerprinted files' do
      @local_files = [
        'public/image.png',
        'public/image-82389298328.png',
        'public/image-a8389f9h324.png',
        'public/application.js',
        'public/application-b3389d983k1.js',
        'public/application-ac387d53f31.js',
        'public',
      ]
      @remote_files = [
        'public/image.png',
        'public/image-a8389f9h324.png',
        'public/application.js',
        'public/application-b3389d983k1.js',
      ]

      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      updated_nonfingerprinted_files = [
        'public/image.png',
        'public/application.js',
      ]
      (@local_files - @remote_files + updated_nonfingerprinted_files).each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end
      storage.upload_files
    end


    it 'should correctly set expire date' do
      local_files = ['file1.jpg', 'file1-1234567890abcdef1234567890abcdef.jpg']
      local_files += ['dir1/dir2/file2.jpg', 'dir1/dir2/file2-1234567890abcdef1234567890abcdef.jpg']
      remote_files = []
      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:local_files).and_return(local_files)
      allow(storage).to receive(:get_remote_files).and_return(remote_files)
      allow(File).to receive(:file?).and_return(true)
      allow(File).to receive(:open).and_return(nil)

      def check_file(file)
        case file[:key]
        when 'file1.jpg'
        when 'dir1/dir2/file2.jpg'
          !expect(file).not_to include(:cache_control, :expires)
        when 'file1-1234567890abcdef1234567890abcdef.jpg'
        when 'dir1/dir2/file2-1234567890abcdef1234567890abcdef.jpg'
          expect(file).to include(:cache_control, :expires)
        else
          fail
        end
      end

      files = double()
      local_files.count.times do
        expect(files).to receive(:create) { |file| check_file(file) }
      end
      allow(storage).to receive_message_chain(:bucket, :files).and_return(files)
      storage.upload_files
    end

    it "shoud invalidate files" do
      @config.cdn_distribution_id = "1234"
      @config.invalidate = ['local_image1.jpg']
      @config.fog_provider = 'AWS'

      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(storage).to receive(:upload_file).and_return(true)

      mock_cdn = double
      expect(Fog::CDN).to receive(:new).and_return(mock_cdn)
      expect(mock_cdn).to receive(:post_invalidation).with("1234", ["/assets/local_image1.jpg"]).and_return(double({:body => {:id => '1234'}}))

      storage.upload_files
    end
  end

  describe '#upload_file' do
    before(:each) do
      # Object#remove_const does not remove the loaded
      # file from the $" variable
      #Object.send(:remove_const, :MIME) if defined?(MIME)
      mime_types = $".grep(/mime\/types/).first
      $".delete(mime_types)
      require 'mime/types'
      @config = AssetSync::Config.new
    end

    it 'accepts custom headers per file' do
      @config.custom_headers = {
        "local_image2.jpg" => {
          :cache_control => 'max-age=0'
        }
      }
      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:open).and_return('file') # Pretend they all exist

      bucket = double
      files = double

      allow(storage).to receive(:bucket).and_return(bucket)
      allow(bucket).to receive(:files).and_return(files)

      expect(files).to receive(:create) do |argument|
        expect(argument[:cache_control]).to eq('max-age=0')
      end
      storage.upload_file('assets/local_image2.jpg')
    end

    it 'accepts custom headers with a regular expression' do
      @config.custom_headers = {
        ".*\.jpg" => {
          :cache_control => 'max-age=0'
        }
      }
      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:open).and_return('file') # Pretend they all exist
      bucket = double
      files = double
      allow(storage).to receive(:bucket).and_return(bucket)
      allow(bucket).to receive(:files).and_return(files)

      expect(files).to receive(:create) do |argument|
        expect(argument[:cache_control]).to eq('max-age=0')
      end
      storage.upload_file('assets/some_longer_path/local_image2.jpg')
    end

    after(:each) do
      #Object.send(:remove_const, :MIME) if defined?(MIME)
    end
  end
end
