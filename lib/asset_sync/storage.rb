module AssetSync
  class Storage
    REGEXP_FINGERPRINTED_FILES = /^(.*)\/([^-]+)-[^\.]+\.([^\.]+)$/

    class BucketNotFound < StandardError;
    end

    attr_accessor :config

    def initialize(cfg)
      @config = cfg
    end

    def connection
      @connection ||= Fog::Storage.new(self.config.fog_options)
    end

    def bucket
      # fixes: https://github.com/rumblelabs/asset_sync/issues/18
      @bucket ||= connection.directories.get(self.config.fog_directory, :prefix => self.config.assets_prefix)
    end

    def log(msg)
      AssetSync.log(msg)
    end

    def keep_existing_remote_files?
      self.config.existing_remote_files?
    end

    def path
      self.config.public_path
    end

    def ignored_files
      files = []
      Array(self.config.ignored_files).each do |ignore|
        case ignore
          when Regexp
            files += self.local_files.select do |file|
              file =~ ignore
            end
          when String
            files += self.local_files.select do |file|
              file.split('/').last == ignore
            end
          else
            log "Error: please define ignored_files as string or regular expression. #{ignore} (#{ignore.class}) ignored."
        end
      end
      files.uniq
    end

    def local_files
      @local_files ||= get_local_files.uniq
    end

    def always_upload_files
      self.config.always_upload.map { |f| File.join(self.config.assets_prefix, f) }
    end

    def files_with_custom_headers
      self.config.custom_headers.inject({}) { |h,(k, v)| h[File.join(self.config.assets_prefix, k)] = v; h; }
    end

    def files_to_invalidate
      self.config.invalidate.map { |filename| File.join("/", self.config.assets_prefix, filename) }
    end

    def get_local_files
      if self.config.manifest
        if ActionView::Base.respond_to?(:assets_manifest)
          log "Using: Rails 4.0 manifest access"
          manifest = Sprockets::Manifest.new(ActionView::Base.assets_manifest.environment, ActionView::Base.assets_manifest.dir)
          return manifest.assets.values.map { |f| File.join(self.config.assets_prefix, f) }
        elsif File.exists?(self.config.manifest_path)
          log "Using: Manifest #{self.config.manifest_path}"
          yml = YAML.load(IO.read(self.config.manifest_path))
   
          return yml.map do |original, compiled|
            # Upload font originals and compiled
            if original =~ /^.+(eot|svg|ttf|woff)$/
              [original, compiled]
            else
              compiled
            end
          end.flatten.map { |f| File.join(self.config.assets_prefix, f) }.uniq!
        else
          log "Warning: Manifest could not be found"
        end
      end
      log "Using: Directory Search of #{path}/#{self.config.assets_prefix}"
      Dir.chdir(path) do
        Dir["#{self.config.assets_prefix}/**/**"]
      end
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
        log "Deleting: #{f.key}"
        f.destroy
      end
    end

    def delete_extra_remote_files
      log "Fetching files to flag for delete"
      remote_files = get_remote_files
      # fixes: https://github.com/rumblelabs/asset_sync/issues/19
      from_remote_files_to_delete = remote_files - local_files - ignored_files - always_upload_files

      log "Flagging #{from_remote_files_to_delete.size} file(s) for deletion"
      # Delete unneeded remote files
      bucket.files.each do |f|
        delete_file(f, from_remote_files_to_delete)
      end
    end

    def upload_file(f)
      # TODO output files in debug logs as asset filename only.
      one_year = 31557600
      ext = File.extname(f)[1..-1]
      mime = MultiMime.lookup(ext)
      file = {
        :key => f,
        :body => File.open("#{path}/#{f}"),
        :public => true,
        :content_type => mime
      }

      if /-[0-9a-fA-F]{32}$/.match(File.basename(f,File.extname(f)))
        file.merge!({
          :cache_control => "public, max-age=#{one_year}",
          :expires => CGI.rfc1123_date(Time.now + one_year)
        })
      end

      # overwrite headers if applicable, you probably shouldn't specific key/body, but cache-control headers etc.

      if files_with_custom_headers.has_key? f
        file.merge! files_with_custom_headers[f]
        log "Overwriting #{f} with custom headers #{files_with_custom_headers[f].to_s}"
      elsif key = self.config.custom_headers.keys.detect {|k| f.match(Regexp.new(k))}
        headers = {}
        self.config.custom_headers[key].each do |key, value|
          headers[key.to_sym] = value
        end
        file.merge! headers
        log "Overwriting matching file #{f} with custom headers #{headers.to_s}"
      end


      gzipped = "#{path}/#{f}.gz"
      ignore = false

      if config.gzip? && File.extname(f) == ".gz"
        # Don't bother uploading gzipped assets if we are in gzip_compression mode
        # as we will overwrite file.css with file.css.gz if it exists.
        log "Ignoring: #{f}"
        ignore = true
      elsif config.gzip? && File.exists?(gzipped)
        original_size = File.size("#{path}/#{f}")
        gzipped_size = File.size(gzipped)

        if gzipped_size < original_size
          percentage = ((gzipped_size.to_f/original_size.to_f)*100).round(2)
          file.merge!({
                        :key => f,
                        :body => File.open(gzipped),
                        :content_encoding => 'gzip'
                      })
          log "Uploading: #{gzipped} in place of #{f} saving #{percentage}%"
        else
          percentage = ((original_size.to_f/gzipped_size.to_f)*100).round(2)
          log "Uploading: #{f} instead of #{gzipped} (compression increases this file by #{percentage}%)"
        end
      else
        if !config.gzip? && File.extname(f) == ".gz"
          # set content encoding for gzipped files this allows cloudfront to properly handle requests with Accept-Encoding
          # http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/ServingCompressedFiles.html
          uncompressed_filename = f[0..-4]
          ext = File.extname(uncompressed_filename)[1..-1]
          mime = MultiMime.lookup(ext)
          file.merge!({
            :content_type     => mime,
            :content_encoding => 'gzip'
          })
        end
        log "Uploading: #{f}"
      end

      if config.aws? && config.aws_rrs?
        file.merge!({
          :storage_class => 'REDUCED_REDUNDANCY'
        })
      end

      file = bucket.files.create( file ) unless ignore
    end

    def upload_files
      # get a fresh list of remote files
      remote_files = ignore_existing_remote_files? ? [] : get_remote_files
      # fixes: https://github.com/rumblelabs/asset_sync/issues/19
      local_files_to_upload = local_files - ignored_files - remote_files + always_upload_files
      local_files_to_upload = (local_files_to_upload + get_non_fingerprinted(local_files_to_upload)).uniq

      # Upload new files
      local_files_to_upload.each do |f|
        next unless File.file? "#{path}/#{f}" # Only files.
        upload_file f
      end

      if self.config.cdn_distribution_id && files_to_invalidate.any?
        log "Invalidating Files"
        cdn ||= Fog::CDN.new(self.config.fog_options.except(:region))
        data = cdn.post_invalidation(self.config.cdn_distribution_id, files_to_invalidate)
        log "Invalidation id: #{data.body["Id"]}"
      end
    end

    def sync
      # fixes: https://github.com/rumblelabs/asset_sync/issues/19
      log "AssetSync: Syncing."
      upload_files
      delete_extra_remote_files unless keep_existing_remote_files?
      log "AssetSync: Done."
    end

    private

    def ignore_existing_remote_files?
      self.config.existing_remote_files == 'ignore'
    end

    def get_non_fingerprinted(files)
      files.map do |file|
        match_data = file.match(REGEXP_FINGERPRINTED_FILES)
        match_data && "#{match_data[1]}/#{match_data[2]}.#{match_data[3]}"
      end.compact
    end

  end
end
