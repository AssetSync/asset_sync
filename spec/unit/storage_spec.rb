require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync::Storage do
  include_context "mock Rails without_yml"

  let(:file_like_object) do
    double("file like object").as_null_object
  end

  describe '#upload_files' do
    before(:each) do
      @local_files = ["local_image2.jpg", "local_image1.jpg", "local_stylesheet1.css", "local_stylesheet2.css"]
      @remote_files = ["local_image.jpg", "local_image3.svg", "local_image4.svg", "local_stylesheet1.css"]
      @config = AssetSync::Config.new
    end

    it 'should overwrite all remote files if set to ignore' do
      @config.existing_remote_files = 'ignore'
      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:get_local_files).and_return(@local_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      @local_files.each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end
      storage.upload_files
    end

    it 'should allow force overwriting of specific files' do
      @config.always_upload = ['local_image.jpg', /local_image\d\.svg/]

      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:get_local_files).and_return(@local_files)
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
      allow(storage).to receive(:get_local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      (@local_files - @remote_files - storage.ignored_files + storage.always_upload_files).each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end
      storage.upload_files
    end

    it 'should upload files concurrently if enabled' do
      @config.concurrent_uploads = true
      storage = AssetSync::Storage.new(@config)

      allow(storage).to receive(:get_local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      expect(Thread).to receive(:new).exactly(3).times.and_call_original
      (@local_files - @remote_files + storage.always_upload_files).each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end

      storage.upload_files
    end

    it 'should allow custom number of threads' do
      @config.concurrent_uploads = true
      @config.concurrent_uploads_max_threads = 2
      storage = AssetSync::Storage.new(@config)

      allow(storage).to receive(:get_local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      expect(Thread).to receive(:new).exactly(2).times.and_call_original
      (@local_files - @remote_files + storage.always_upload_files).each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end

      storage.upload_files
    end

    it 'should allow remote_file_list_cache_file_path configuration' do
      file_path = './foo.json'
      @config.remote_file_list_cache_file_path = file_path
      storage = AssetSync::Storage.new(@config)

      allow(storage).to receive(:get_local_files).and_return(@local_files)
      File.write(file_path, @remote_files.to_json)
      expect(storage).not_to receive(:get_remote_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      (@local_files - @remote_files + storage.always_upload_files).each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end

      expect(storage).not_to receive(:warn)
      storage.upload_files

      # update remote_file_list_cache corretly
      updated = JSON.parse(File.read(file_path))
      expect(updated.sort.uniq).to eq (@remote_files + @local_files + storage.always_upload_files).sort.uniq

      File.delete(file_path)
    end

    it 'should work with broken cache' do
      file_path = './foo.json'
      @config.remote_file_list_cache_file_path = file_path

      storage = AssetSync::Storage.new(@config)

      File.write(file_path, 'some non-json text file content')

      allow(storage).to receive(:get_local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      allow(File).to receive(:file?).and_return(true) # Pretend they all exist

      (@local_files - @remote_files + storage.always_upload_files).each do |file|
        expect(storage).to receive(:upload_file).with(file)
      end

      # when broken, warning message should be prompted
      expect(storage).to receive(:warn)

      storage.upload_files

      File.delete(file_path)
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
      allow(storage).to receive(:get_local_files).and_return(@local_files)
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

    context "when config #add_local_file_paths is called" do
      let(:additional_local_file_paths) do
        ["webpack/example_asset.jpg"]
      end

      before(:each) do
        @config.add_local_file_paths do
          additional_local_file_paths
        end
      end

      let(:storage) do
        AssetSync::Storage.new(@config)
      end

      let(:file_paths_should_be_uploaded) do
        @local_files -
          @remote_files -
          storage.ignored_files +
          storage.always_upload_files +
          additional_local_file_paths
      end

      before do
        # Stubbing
        allow(storage).to receive(:get_local_files).and_return(@local_files)
        allow(storage).to receive(:get_remote_files).and_return(@remote_files)
        # Pretend the files all exist
        allow(File).to receive(:file?).and_return(true)
      end

      it "uploads additional files in additional to local files" do
        file_paths_should_be_uploaded.each do |file|
          expect(storage).to receive(:upload_file).with(file)
        end
        storage.upload_files
      end
    end

    it 'should upload additonal files' do
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
      allow(storage).to receive(:get_local_files).and_return(@local_files)
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
      local_files = [
        'file1.jpg',
        'file1-1234567890abcdef1234567890abcdef.jpg',
        'file1-1234567890abcdef1234567890abcdef.jpg.gz',
        'file1-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.jpg',
        'file1-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.jpg.gz'
      ]
      local_files += [
        'dir1/dir2/file2.jpg',
        'dir1/dir2/file2-1234567890abcdef1234567890abcdef.jpg',
        'dir1/dir2/file2-1234567890abcdef1234567890abcdef.jpg.gz',
        'dir1/dir2/file2-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.jpg',
        'dir1/dir2/file2-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.jpg.gz'
      ]
      local_files += [
        'file3.png',
        'file3.zabcde.png',
        'file3.zab1cde2.png',
        'file3.abcdef.jpg',
        'file3.abc1def2.jpg',
        'dir3/file3.abc123.jpg',
        'dir3/file3.abcdf123.jpg'
      ]
      remote_files = []
      @config.cache_asset_regexps = [/\.[a-f0-9]{6}$/i, /\.[a-f0-9]{8}$/i]
      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:get_local_files).and_return(local_files)
      allow(storage).to receive(:get_remote_files).and_return(remote_files)
      allow(File).to receive(:file?).and_return(true)
      allow(File).to receive(:open).and_return(file_like_object)

      def check_file(file)
        case file[:key]
        when 'file1.jpg',
             'dir1/dir2/file2.jpg',
             'file3.png',
             'file3.zabcde.png',
             'file3.zab1cde2.png'
          !expect(file).not_to include(:cache_control, :expires)
        when 'file1-1234567890abcdef1234567890abcdef.jpg',
             'file1-1234567890abcdef1234567890abcdef.jpg.gz',
             'file1-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.jpg',
             'file1-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.jpg.gz',
             'dir1/dir2/file2-1234567890abcdef1234567890abcdef.jpg',
             'dir1/dir2/file2-1234567890abcdef1234567890abcdef.jpg.gz',
             'dir1/dir2/file2-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.jpg',
             'dir1/dir2/file2-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.jpg.gz',
             'file3.abcdef.jpg',
             'file3.abc1def2.jpg',
             'dir3/file3.abc123.jpg',
             'dir3/file3.abcdf123.jpg'
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

    it "should invalidate files" do
      @config.cdn_distribution_id = "1234"
      @config.invalidate = ['local_image1.jpg']
      @config.fog_provider = 'AWS'

      storage = AssetSync::Storage.new(@config)
      allow(storage).to receive(:get_local_files).and_return(@local_files)
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
      #
      # So we need do both
      #
      # 1. Remove constant(s) to avoid warning messages
      # 2. Remove loaded file(s)
      Object.send(:remove_const, :MIME) if defined?(MIME)

      $".grep(/mime\//).each do |file_path|
        $".delete(file_path)
      end
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
      allow(storage).to receive(:get_local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      # Pretend they all exist
      allow(File).to receive(:open).and_return(file_like_object)

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
      allow(storage).to receive(:get_local_files).and_return(@local_files)
      allow(storage).to receive(:get_remote_files).and_return(@remote_files)
      # Pretend they all exist
      allow(File).to receive(:open).and_return(file_like_object)
      bucket = double
      files = double
      allow(storage).to receive(:bucket).and_return(bucket)
      allow(bucket).to receive(:files).and_return(files)

      expect(files).to receive(:create) do |argument|
        expect(argument[:cache_control]).to eq('max-age=0')
      end
      storage.upload_file('assets/some_longer_path/local_image2.jpg')
    end
  end

  describe '#delete_extra_remote_files' do
    it 'should delete the files in bulk' do
      remote_files = ['public/image.png']
      connection = double
      config = double

      storage = AssetSync::Storage.new(@config)

      [:local_files, :ignored_files, :always_upload_files].each do |method|
        expect(storage).to receive(method).and_return([])
      end

      allow(storage).to receive(:get_remote_files).and_return(remote_files)
      allow(storage).to receive(:connection).and_return(connection).twice
      allow(storage).to receive(:config).and_return(config).twice
      allow(config).to receive(:aws?).and_return(true)
      allow(config).to receive(:fog_directory).and_return('foo')
      expect(connection).to receive(:delete_multiple_objects).with('foo', remote_files)

      storage.delete_extra_remote_files
    end

    context 'when not aws' do
      it 'deletes files sequentially' do
        remote_files = ['public/image.png']
        connection = double
        config = double
        directories = double
        directory = double
        file = double

        storage = AssetSync::Storage.new(@config)

        [:local_files, :ignored_files, :always_upload_files].each do |method|
          expect(storage).to receive(method).and_return([])
        end

        allow(storage).to receive(:get_remote_files).and_return(remote_files)
        allow(storage).to receive(:connection).and_return(connection).twice
        allow(storage).to receive(:config).and_return(config)
        allow(config).to receive(:aws?).and_return(false)
        allow(config).to receive(:fog_directory).and_return('foo')
        allow(config).to receive(:assets_prefix).and_return('foo')
        allow(directories).to receive(:get).and_return(directory)
        allow(directory).to receive(:files).and_return([file])
        allow(file).to receive(:key).and_return('public/image.png')
        allow(connection).to receive(:directories).and_return(directories)
        expect(connection).not_to receive(:delete_multiple_objects)
        expect(file).to receive(:destroy)

        storage.delete_extra_remote_files
      end
    end
  end
end
