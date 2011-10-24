module AssetSync
  class Config
    include ActiveModel::Validations

    class Invalid < StandardError; end

    # AssetSync
    attr_accessor :existing_remote_files # What to do with your existing remote files? (keep or delete)
    attr_accessor :gzip_compression
    attr_accessor :manifest

    # FOG configuration
    attr_accessor :fog_provider          # Currently Supported ['AWS', 'Rackspace']
    attr_accessor :fog_directory         # e.g. 'the-bucket-name'
    attr_accessor :fog_region            # e.g. 'eu-west-1'

    # Amazon AWS
    attr_accessor :aws_access_key_id, :aws_secret_access_key

    # Rackspace
    attr_accessor :rackspace_username, :rackspace_api_key

    validates :existing_remote_files, :inclusion => { :in => %w(keep delete) }

    validates :fog_provider,          :presence => true
    validates :fog_directory,         :presence => true

    validates :aws_access_key_id,     :presence => true, :if => :aws?
    validates :aws_secret_access_key, :presence => true, :if => :aws?
    validates :rackspace_username,    :presence => true, :if => :rackspace?
    validates :rackspace_api_key,     :presence => true, :if => :rackspace?

    def initialize
      self.fog_region = nil
      self.existing_remote_files = 'keep'
      self.gzip_compression = false
      self.manifest = false
      load_yml! if yml_exists?
    end

    def manifest_path
      default = File.join(Rails.root, 'public', 'assets', 'manifest.yml')
      Rails.application.config.assets.manifest || default
    end

    def gzip?
      self.gzip_compression
    end

    def existing_remote_files?
      (self.existing_remote_files == "keep")
    end

    def aws?
      fog_provider == 'AWS'
    end

    def rackspace?
      fog_provider == 'Rackspace'
    end

    def yml_exists?
      File.exists?(self.yml_path)
    end

    def yml
      y ||= YAML.load(ERB.new(IO.read(yml_path)).result)[Rails.env] rescue nil || {}
    end

    def yml_path
      File.join(Rails.root, "config/asset_sync.yml")
    end

    def load_yml!
      self.fog_provider          = yml["fog_provider"]
      self.fog_directory         = yml["fog_directory"]
      self.fog_region            = yml["fog_region"]
      self.aws_access_key_id     = yml["aws_access_key_id"]
      self.aws_secret_access_key = yml["aws_secret_access_key"]
      self.rackspace_username    = yml["rackspace_username"]
      self.rackspace_api_key     = yml["rackspace_api_key"]
      self.existing_remote_files  = yml["existing_remote_files"] if yml.has_key?("existing_remote_files")
      self.gzip_compression       = yml["gzip_compression"] if yml.has_key?("gzip_compression")
      self.manifest               = yml["manifest"] if yml.has_key?("manifest")

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
    end


    def fog_options
      options = { :provider => provider }
      if aws?
        options.merge!({
          :aws_access_key_id => aws_access_key,
          :aws_secret_access_key => aws_access_secret
        })
      elsif rackspace?
        options.merge!({
          :rackspace_username => rackspace_username,
          :rackspace_api_key => rackspace_api_key
        })
      else
        raise ArgumentError, "AssetSync Unknown provider: #{fog_provider} only AWS and Rackspace are supported currently."
      end

      options.merge!({:region => fog_region}) if fog_region
      return options
    end

  end
end
