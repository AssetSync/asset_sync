module AssetSync
  class Storage

    class BucketNotFound < StandardError; end

    attr_accessor :config

    def initialize(cfg)
      @config = cfg
    end

    def connection
      @connection ||= Fog::Storage.new(self.config.fog_options)
    end

    def bucket
      # fixes: https://github.com/rumblelabs/asset_sync/issues/18
      @bucket ||= connection.directories.get(self.config.fog_directory, :prefix => Rails.application.config.assets.prefix)
    end

    def keep_existing_remote_files?
      self.config.existing_remote_files?
    end

    def path
      "#{Rails.root.to_s}/public"
    end

    def local_files
      @local_files ||= get_local_files
    end

    def get_local_files
      if self.config.manifest
        if File.exists?(self.config.manifest_path)
          yml = YAML.load(IO.read(self.config.manifest_path))
          STDERR.puts "Using: Manifest #{self.config.manifest_path}"
          return yml.values.map { |f| File.join(Rails.application.config.assets.prefix, f) }
        else
          STDERR.puts "Warning: manifest.yml not found at #{self.config.manifest_path}"
        end
      end
      STDERR.puts "Using: Directory Search of #{path}/#{Rails.application.config.assets.prefix}"
      Dir["#{path}/#{Rails.application.config.assets.prefix}/**/**"].map { |f| f[path.length+1,f.length-path.length] }
    end

    def get_remote_files
      raise BucketNotFound.new("#{self.config.fog_provider} Bucket: #{self.config.fog_directory} not found.") unless bucket
      # fixes: https://github.com/rumblelabs/asset_sync/issues/16
      #        (work-around for https://github.com/fog/fog/issues/596)
      files = []
      bucket.files.each { |f| files << f.key }
      return files
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
      # fixes: https://github.com/rumblelabs/asset_sync/issues/19
      from_remote_files_to_delete = remote_files - local_files

      STDERR.puts "Flagging #{from_remote_files_to_delete.size} file(s) for deletion"
      # Delete unneeded remote files
      bucket.files.each do |f|
        delete_file(f, from_remote_files_to_delete)
      end
    end

    def upload_file(f)
      # TODO output files in debug logs as asset filename only.
      file = {
        :key => f,
        :body => File.open("#{path}/#{f}"),
        :public => true,
        :cache_control => "max-age=31557600"
      }

      gzipped = "#{path}/#{f}.gz"
      ignore = false

      if config.gzip? && File.extname(f) == ".gz"
        # Don't bother uploading gzipped assets if we are in gzip_compression mode
        # as we will overwrite file.css with file.css.gz if it exists.
        STDERR.puts "Ignoring: #{f}"
        ignore = true
      elsif config.gzip? && File.exists?(gzipped)
        original_size = File.size("#{path}/#{f}")
        gzipped_size  = File.size(gzipped)

        if gzipped_size < original_size
          percentage = ((gzipped_size.to_f/original_size.to_f)*100).round(2)
          ext = File.extname( f )[1..-1]
          mime = Mime::Type.lookup_by_extension( ext )
          file.merge!({
            :key => f,
            :body => File.open(gzipped),
            :content_type     => mime,
            :content_encoding => 'gzip'
          })
          STDERR.puts "Uploading: #{gzipped} in place of #{f} saving #{percentage}%"
        else
          percentage = ((original_size.to_f/gzipped_size.to_f)*100).round(2)
          STDERR.puts "Uploading: #{f} instead of #{gzipped} (compression increases this file by #{percentage}%)"
        end
      else
        STDERR.puts "Uploading: #{f}"
      end

      file = bucket.files.create( file ) unless ignore
    end

    def upload_files
      # get a fresh list of remote files
      remote_files = get_remote_files
      # fixes: https://github.com/rumblelabs/asset_sync/issues/19
      local_files_to_upload = local_files - remote_files

      # Upload new files
      local_files_to_upload.each do |f|
        next unless File.file? "#{path}/#{f}" # Only files.
        upload_file f
      end
    end

    def sync
      # fixes: https://github.com/rumblelabs/asset_sync/issues/19
       upload_files
       delete_extra_remote_files unless keep_existing_remote_files?
       STDERR.puts "Done."
    end

  end
end
