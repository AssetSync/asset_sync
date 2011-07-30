module AssetSync
  class Assets

    def self.s3_config
      @config ||= YAML.load_file(File.join(Rails.root, "config/asset_sync.yml"))[Rails.env] rescue nil || {}
    end

    def self.connection
      Fog::Storage.new(
        :provider => 'AWS', 
        :aws_access_key_id => s3_config["access_key_id"],
        :aws_secret_access_key => s3_config["secret_access_key"]
      )
    end

    def self.bucket
      @bucket ||= connection.directories.get(s3_config["bucket"])
    end
    
    def self.path
      "#{Rails.root.to_s}/public"
    end
    
    def self.local_files
      Dir["#{path}/assets/**/**"].map { |f| f[path.length+1,f.length-path.length] }
    end

    def self.get_remote_files
      return bucket.files.map { |f| f.key }
    end

    def self.delete_file(f, remote_files_to_delete)
      if remote_files_to_delete.include?(f.key)
        STDERR.puts "Deleting: #{f.key}"
        f.destroy
      end
    end

    def self.delete_extra_remote_files
      remote_files = get_remote_files
      from_remote_files_to_delete = (local_files | remote_files) - (local_files & remote_files)

      # Delete unneeded remote files
      bucket.files.each do |f|
        delete_file(f, from_remote_files_to_delete)
      end
    end

    def self.upload_file(f)
      STDERR.puts "Uploading: #{f}"
      file = bucket.files.create(
        :key => "#{f}",
        :body => File.open("#{path}/#{f}"),
        :public => true
      )
    end

    def self.upload_files
      # get a fresh list of remote files
      remote_files = get_remote_files
      local_files_to_upload = (remote_files | local_files) - (remote_files & local_files)

      # Upload new files
      local_files_to_upload.each do |f|
        next unless File.file? "#{path}/#{f}" # Only files.
        upload_file f
      end
    end

    def self.sync
       delete_extra_remote_files   
       upload_files
       STDERR.puts "Done."
    end    
  end
end
