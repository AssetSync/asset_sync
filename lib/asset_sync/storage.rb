module AssetSync
  class Storage

    attr_accessor :config

    def initialize(cfg)
      @config = cfg
    end

    def connection
      @connection ||= Fog::Storage.new(self.config.fog_options)
    end

    def bucket
      @bucket ||= connection.directories.get(self.config.aws_bucket)
    end

    def keep_existing_remote_files?
      self.config.existing_remote_files?
    end

    def path
      "#{Rails.root.to_s}/public"
    end

    def local_files
      Dir["#{path}/assets/**/**"].map { |f| f[path.length+1,f.length-path.length] }
    end

    def get_remote_files
      return bucket.files.map { |f| f.key }
    end

    def delete_file(f, remote_files_to_delete)
      if remote_files_to_delete.include?(f.key)
        STDERR.puts "Deleting: #{f.key}"
        f.destroy
      end
    end

    def delete_extra_remote_files
      STDERR.puts "Fetching files to flag for delete"
      remote_files = get_remote_files
      from_remote_files_to_delete = (local_files | remote_files) - (local_files & remote_files)
      
      STDERR.puts "Flagging #{from_remote_files_to_delete.size} file(s) for deletion"
      # Delete unneeded remote files
      bucket.files.each do |f|
        delete_file(f, from_remote_files_to_delete)
      end
    end

    def upload_file(f)
      STDERR.puts "Uploading: #{f}"
      file = bucket.files.create(
        :key => "#{f}",
        :body => File.open("#{path}/#{f}"),
        :public => true,
        :cache_control => "max-age=31557600"
      )
    end

    def upload_files
      # get a fresh list of remote files
      remote_files = get_remote_files
      local_files_to_upload = (remote_files | local_files) - (remote_files & local_files)

      # Upload new files
      local_files_to_upload.each do |f|
        next unless File.file? "#{path}/#{f}" # Only files.
        upload_file f
      end
    end

    def sync
       delete_extra_remote_files unless keep_existing_remote_files?
       upload_files
       STDERR.puts "Done."
    end

  end
end