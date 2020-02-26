# frozen_string_literal: true

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
    attr_accessor :enabled
    attr_accessor :custom_headers
    attr_accessor :run_on_precompile
    attr_accessor :invalidate
    attr_accessor :cdn_distribution_id
    attr_accessor :cache_asset_regexps
    attr_accessor :include_manifest
    attr_accessor :concurrent_uploads
    attr_accessor :concurrent_uploads_max_threads

    # FOG configuration
    attr_accessor :fog_provider          # Currently Supported ['AWS', 'Rackspace']
    attr_accessor :fog_directory         # e.g. 'the-bucket-name'
    attr_accessor :fog_region            # e.g. 'eu-west-1'
    attr_reader   :fog_public            # e.g. true, false, "default"

    # Amazon AWS
    attr_accessor :aws_access_key_id, :aws_secret_access_key, :aws_reduced_redundancy, :aws_iam_roles, :aws_signature_version
    attr_accessor :fog_host              # e.g. 's3.amazonaws.com'
    attr_accessor :fog_port              # e.g. '9000'
    attr_accessor :fog_path_style        # e.g. true
    attr_accessor :fog_scheme            # e.g. 'http'

    # Rackspace
    attr_accessor :rackspace_username, :rackspace_api_key, :rackspace_auth_url

    # Google Storage
    attr_accessor :google_storage_secret_access_key, :google_storage_access_key_id  # when using S3 interop
    attr_accessor :google_json_key_location # when using service accounts
    attr_accessor :google_project # when using service accounts

    # Azure Blob with Fog::AzureRM
    attr_accessor :azure_storage_account_name
    attr_accessor :azure_storage_access_key

    validates :existing_remote_files, :inclusion => { :in => %w(keep delete ignore) }

    validates :fog_provider,          :presence => true
    validates :fog_directory,         :presence => true

    validates :aws_access_key_id,     :presence => true, :if => proc {aws? && !aws_iam?}
    validates :aws_secret_access_key, :presence => true, :if => proc {aws? && !aws_iam?}
    validates :rackspace_username,    :presence => true, :if => :rackspace?
    validates :rackspace_api_key,     :presence => true, :if => :rackspace?
    validates :google_storage_secret_access_key,  :presence => true, :if => :google_interop?
    validates :google_storage_access_key_id,      :presence => true, :if => :google_interop?
    validates :google_json_key_location,          :presence => true, :if => :google_service_account?
    validates :google_project,                    :presence => true, :if => :google_service_account?
    validates :concurrent_uploads,    :inclusion => { :in => [true, false] }

    def initialize
      self.fog_region = nil
      self.fog_public = true
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
      self.invalidate = []
      self.cache_asset_regexps = []
      self.include_manifest = false
      self.concurrent_uploads = false
      self.concurrent_uploads_max_threads = 10
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

    def google_interop?
      google? && google_json_key_location.nil?
    end

    def google_service_account?
      google? && google_json_key_location
    end

    def azure_rm?
      fog_provider =~ /azurerm/i
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

    def public_path=(path)
      # Generate absolute path even when relative path passed in
      # Required for generating relative sprockets manifest path
      pathname = Pathname(path)
      @public_path = if pathname.absolute?
        pathname
      elsif defined?(::Rails.root)
        ::Rails.root.join(pathname)
      else
        Pathname(::Dir.pwd).join(pathname)
      end
    end

    def load_yml!
      self.enabled                = yml["enabled"] if yml.has_key?('enabled')
      self.fog_provider           = yml["fog_provider"]
      self.fog_host               = yml["fog_host"]
      self.fog_port               = yml["fog_port"]
      self.fog_directory          = yml["fog_directory"]
      self.fog_region             = yml["fog_region"]
      self.fog_public             = yml["fog_public"] if yml.has_key?("fog_public")
      self.fog_path_style         = yml["fog_path_style"]
      self.fog_scheme             = yml["fog_scheme"]
      self.aws_access_key_id      = yml["aws_access_key_id"]
      self.aws_secret_access_key  = yml["aws_secret_access_key"]
      self.aws_reduced_redundancy = yml["aws_reduced_redundancy"]
      self.aws_iam_roles          = yml["aws_iam_roles"]
      self.aws_signature_version  = yml["aws_signature_version"]
      self.rackspace_username     = yml["rackspace_username"]
      self.rackspace_auth_url     = yml["rackspace_auth_url"] if yml.has_key?("rackspace_auth_url")
      self.rackspace_api_key      = yml["rackspace_api_key"]
      self.google_json_key_location = yml["google_json_key_location"] if yml.has_key?("google_json_key_location")
      self.google_project = yml["google_project"] if yml.has_key?("google_project")
      self.google_storage_secret_access_key = yml["google_storage_secret_access_key"] if yml.has_key?("google_storage_secret_access_key")
      self.google_storage_access_key_id     = yml["google_storage_access_key_id"] if yml.has_key?("google_storage_access_key_id")
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
      self.include_manifest       = yml['include_manifest'] if yml.has_key?("include_manifest")
      self.concurrent_uploads     = yml['concurrent_uploads'] if yml.has_key?('concurrent_uploads')
      self.concurrent_uploads_max_threads = yml['concurrent_uploads_max_threads'] if yml.has_key?('concurrent_uploads_max_threads')

      self.azure_storage_account_name = yml['azure_storage_account_name'] if yml.has_key?("azure_storage_account_name")
      self.azure_storage_access_key   = yml['azure_storage_access_key'] if yml.has_key?("azure_storage_access_key")

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
        options.merge!({:host => fog_host}) if fog_host
        options.merge!({:port => fog_port}) if fog_port
        options.merge!({:scheme => fog_scheme}) if fog_scheme
        options.merge!({:aws_signature_version => aws_signature_version}) if aws_signature_version
        options.merge!({:path_style => fog_path_style}) if fog_path_style
        options.merge!({:region => fog_region}) if fog_region
      elsif rackspace?
        options.merge!({
          :rackspace_username => rackspace_username,
          :rackspace_api_key => rackspace_api_key
        })
        options.merge!({ :rackspace_region => fog_region }) if fog_region
        options.merge!({ :rackspace_auth_url => rackspace_auth_url }) if rackspace_auth_url
      elsif google?
        if google_json_key_location
          options.merge!({:google_json_key_location => google_json_key_location, :google_project => google_project})
        else
          options.merge!({
            :google_storage_secret_access_key => google_storage_secret_access_key,
            :google_storage_access_key_id => google_storage_access_key_id
          })
        end
        options.merge!({:region => fog_region}) if fog_region
      elsif azure_rm?
        require 'fog/azurerm'
        options.merge!({
          :azure_storage_account_name => azure_storage_account_name,
          :azure_storage_access_key   => azure_storage_access_key,
        })
        options.merge!({:environment => fog_region}) if fog_region
      else
        raise ArgumentError, "AssetSync Unknown provider: #{fog_provider} only AWS, Rackspace and Google are supported currently."
      end

      options
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

    #@api
    def file_ext_to_mime_type_overrides
      @file_ext_to_mime_type_overrides ||= FileExtToMimeTypeOverrides.new
    end

    def fog_public=(new_val)
      @fog_public = FogPublicValue.new(new_val)
    end

  private

    # This is a proc to get additional local files paths
    # Since this is a proc it won't be able to be configured by a YAML file
    attr_reader :additional_local_file_paths_procs

    def default_manifest_directory
      File.join(::Rails.public_path, assets_prefix)
    end


    # @api private
    class FileExtToMimeTypeOverrides
      def initialize
        # The default is to prevent new mime type `application/ecmascript` to be returned
        # which disables compression on some CDNs
        @overrides = {
          "js" => "application/javascript",
        }
      end

      # @api
      def add(ext, mime_type)
        # Symbol / Mime type object might be passed in
        # But we want strings only
        @overrides.store(
          ext.to_s, mime_type.to_s,
        )
      end

      # @api
      def clear
        @overrides = {}
      end


      # @api private
      def key?(key)
        @overrides.key?(key)
      end

      # @api private
      def fetch(key)
        @overrides.fetch(key)
      end
    end

    # @api private
    class FogPublicValue
      def initialize(val)
        @value = val
      end

      def use_explicit_value?
        @value.to_s != "default"
      end

      def to_bool
        !!@value
      end
    end
  end
end
