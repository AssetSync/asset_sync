require "active_model"
require "erb"
require "yaml"

module AssetSync
  class Config
    include ActiveModel::Validations

    class Invalid < StandardError; end

    # AssetSync
    attr_accessor :existing_remote_files # What to do with your existing remote files? (keep or delete)
    attr_accessor :gzip_compression
    attr_accessor :manifest
    attr_accessor :fail_silently
    attr_accessor :log_silently
    attr_accessor :always_upload
    attr_accessor :ignored_files
    attr_accessor :prefix
    attr_accessor :public_path
    attr_accessor :enabled
    attr_accessor :custom_headers
    attr_accessor :run_on_precompile
    attr_accessor :invalidate
    attr_accessor :cdn_distribution_id
    attr_accessor :cache_asset_regexps
    attr_accessor :include_webpacker_assets

    # FOG configuration
    attr_accessor :fog_provider          # Currently Supported ['AWS', 'Rackspace']
    attr_accessor :fog_directory         # e.g. 'the-bucket-name'
    attr_accessor :fog_region            # e.g. 'eu-west-1'
    attr_accessor :fog_path_style        # e.g true

    # Amazon AWS
    attr_accessor :aws_access_key_id, :aws_secret_access_key, :aws_reduced_redundancy, :aws_iam_roles

    # Rackspace
    attr_accessor :rackspace_username, :rackspace_api_key, :rackspace_auth_url

    # Google Storage
    attr_accessor :google_storage_secret_access_key, :google_storage_access_key_id

    validates :existing_remote_files, :inclusion => { :in => %w(keep delete ignore) }

    validates :fog_provider,          :presence => true
    validates :fog_directory,         :presence => true

    validates :aws_access_key_id,     :presence => true, :if => proc {aws? && !aws_iam?}
    validates :aws_secret_access_key, :presence => true, :if => proc {aws? && !aws_iam?}
    validates :rackspace_username,    :presence => true, :if => :rackspace?
    validates :rackspace_api_key,     :presence => true, :if => :rackspace?
    validates :google_storage_secret_access_key,  :presence => true, :if => :google?
    validates :google_storage_access_key_id,      :presence => true, :if => :google?

    def initialize
      self.fog_region = nil
      self.existing_remote_files = 'keep'
      self.gzip_compression = false
      self.manifest = false
      self.fail_silently = false
      self.log_silently = true
      self.always_upload = []
      self.ignored_files = []
      self.custom_headers = {}
      self.enabled = true
      self.run_on_precompile = true
      self.cdn_distribution_id = nil
      self.include_webpacker_assets = false
      self.invalidate = []
      self.cache_asset_regexps = []
      @additional_local_file_paths_procs = []

      load_yml! if defined?(::Rails) && yml_exists?
    end

    def manifest_path
      directory =
        ::Rails.application.config.assets.manifest || default_manifest_directory
      File.join(directory, "manifest.yml")
    end

    def gzip?
      self.gzip_compression
    end

    def existing_remote_files?
      ['keep', 'ignore'].include?(self.existing_remote_files)
    end

    def aws?
      fog_provider =~ /aws/i
    end

    def aws_rrs?
      aws_reduced_redundancy == true
    end

    def aws_iam?
      aws_iam_roles == true
    end

    def fail_silently?
      fail_silently || !enabled?
    end

    def log_silently?
      !!self.log_silently
    end

    def enabled?
      enabled == true
    end

    def rackspace?
      fog_provider =~ /rackspace/i
    end

    def google?
      fog_provider =~ /google/i
    end

    def cache_asset_regexp=(cache_asset_regexp)
      self.cache_asset_regexps = [cache_asset_regexp]
    end

    def yml_exists?
      defined?(::Rails.root) ? File.exist?(self.yml_path) : false
    end

    def yml
      @yml ||= ::YAML.load(::ERB.new(IO.read(yml_path)).result)[::Rails.env] || {}
    end

    def yml_path
      ::Rails.root.join("config", "asset_sync.yml").to_s
    end

    def assets_prefix
      # Fix for Issue #38 when Rails.config.assets.prefix starts with a slash
      self.prefix || ::Rails.application.config.assets.prefix.sub(/^\//, '')
    end

    def public_path
      @public_path || ::Rails.public_path
    end

    def load_yml!
      self.enabled                = yml["enabled"] if yml.has_key?('enabled')
      self.fog_provider           = yml["fog_provider"]
      self.fog_directory          = yml["fog_directory"]
      self.fog_region             = yml["fog_region"]
      self.fog_path_style         = yml["fog_path_style"]
      self.aws_access_key_id      = yml["aws_access_key_id"]
      self.aws_secret_access_key  = yml["aws_secret_access_key"]
      self.aws_reduced_redundancy = yml["aws_reduced_redundancy"]
      self.aws_iam_roles          = yml["aws_iam_roles"]
      self.rackspace_username     = yml["rackspace_username"]
      self.rackspace_auth_url     = yml["rackspace_auth_url"] if yml.has_key?("rackspace_auth_url")
      self.rackspace_api_key      = yml["rackspace_api_key"]
      self.google_storage_secret_access_key = yml["google_storage_secret_access_key"]
      self.google_storage_access_key_id     = yml["google_storage_access_key_id"]
      self.existing_remote_files  = yml["existing_remote_files"] if yml.has_key?("existing_remote_files")
      self.gzip_compression       = yml["gzip_compression"] if yml.has_key?("gzip_compression")
      self.manifest               = yml["manifest"] if yml.has_key?("manifest")
      self.fail_silently          = yml["fail_silently"] if yml.has_key?("fail_silently")
      self.always_upload          = yml["always_upload"] if yml.has_key?("always_upload")
      self.ignored_files          = yml["ignored_files"] if yml.has_key?("ignored_files")
      self.custom_headers          = yml["custom_headers"] if yml.has_key?("custom_headers")
      self.run_on_precompile      = yml["run_on_precompile"] if yml.has_key?("run_on_precompile")
      self.invalidate             = yml["invalidate"] if yml.has_key?("invalidate")
      self.cdn_distribution_id    = yml['cdn_distribution_id'] if yml.has_key?("cdn_distribution_id")
      self.cache_asset_regexps    = yml['cache_asset_regexps'] if yml.has_key?("cache_asset_regexps")
      self.include_webpacker_assets = yml['include_webpacker_assets'] if yml.has_key?("include_webpacker_assets")

      # TODO deprecate the other old style config settings. FML.
      self.aws_access_key_id      = yml["aws_access_key"] if yml.has_key?("aws_access_key")
      self.aws_secret_access_key  = yml["aws_access_secret"] if yml.has_key?("aws_access_secret")
      self.fog_directory          = yml["aws_bucket"] if yml.has_key?("aws_bucket")
      self.fog_region             = yml["aws_region"] if yml.has_key?("aws_region")

      # TODO deprecate old style config settings
      self.aws_access_key_id      = yml["access_key_id"] if yml.has_key?("access_key_id")
      self.aws_secret_access_key  = yml["secret_access_key"] if yml.has_key?("secret_access_key")
      self.fog_directory          = yml["bucket"] if yml.has_key?("bucket")
      self.fog_region             = yml["region"] if yml.has_key?("region")

      self.public_path            = yml["public_path"] if yml.has_key?("public_path")
    end


    def fog_options
      options = { :provider => fog_provider }
      if aws?
        if aws_iam?
          options.merge!({
            :use_iam_profile => true
          })
        else
          options.merge!({
            :aws_access_key_id => aws_access_key_id,
            :aws_secret_access_key => aws_secret_access_key
          })
        end
      elsif rackspace?
        options.merge!({
          :rackspace_username => rackspace_username,
          :rackspace_api_key => rackspace_api_key
        })
        options.merge!({
          :rackspace_region => fog_region
        }) if fog_region
        options.merge!({ :rackspace_auth_url => rackspace_auth_url }) if rackspace_auth_url
      elsif google?
        options.merge!({
          :google_storage_secret_access_key => google_storage_secret_access_key,
          :google_storage_access_key_id => google_storage_access_key_id
        })
      else
        raise ArgumentError, "AssetSync Unknown provider: #{fog_provider} only AWS, Rackspace and Google are supported currently."
      end

      options.merge!({:region => fog_region}) if fog_region && !rackspace?
      options.merge!({:path_style => fog_path_style}) if fog_path_style && aws?
      return options
    end

    # @api
    def add_local_file_paths(&block)
      @additional_local_file_paths_procs =
        additional_local_file_paths_procs + [block]
    end

    # @api private
    #   This is to be called in Storage
    #   Not to be called by user
    def additional_local_file_paths
      return [] if additional_local_file_paths_procs.empty?

      # Using `Array()` to ensure it works when single value is returned
      additional_local_file_paths_procs.each_with_object([]) do |proc, paths|
        paths.concat(Array(proc.call))
      end
    end

  private

    # This is a proc to get additional local files paths
    # Since this is a proc it won't be able to be configured by a YAML file
    attr_reader :additional_local_file_paths_procs

    def default_manifest_directory
      File.join(::Rails.public_path, assets_prefix)
    end
  end
end
