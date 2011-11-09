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
      @bucket ||= connection.directories.get(self.config.aws_bucket, :prefix => 'assets')
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
        path = File.join(self.config.manifest, 'manifest.yml')
        if File.exists?(path)
          yml = YAML.load(IO.read(path))
          return yml.values.map { |f| File.join('assets', f) }
        end
      end
      Dir["#{path}/assets/**/**"].map { |f| f[path.length+1,f.length-path.length] }
    end 

    def get_remote_files
      raise BucketNotFound.new("AWS Bucket: #{self.config.aws_bucket} not found.") unless bucket
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
      from_remote_files_to_delete = (local_files | remote_files) - (local_files & remote_files)
      
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
