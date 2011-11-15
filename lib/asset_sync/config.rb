module AssetSync
  class Config
    include ActiveModel::Validations

    class Invalid < StandardError; end

    attr_accessor :provider
    attr_accessor :aws_access_key, :aws_access_secret
    attr_accessor :aws_bucket
    attr_accessor :aws_region
    attr_accessor :existing_remote_files
    attr_accessor :gzip_compression
    attr_accessor :manifest

    validates :aws_access_key,        :presence => true
    validates :aws_access_secret,     :presence => true
    validates :aws_bucket,            :presence => true
    validates :existing_remote_files, :inclusion => {:in => %w(keep delete)}

    def initialize
      self.provider = 'AWS'
      self.aws_region = nil
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
      self.aws_access_key         = yml["aws_access_key"] if yml.has_key?("aws_access_key")
      self.aws_access_secret      = yml["aws_access_secret"] if yml.has_key?("aws_access_secret")
      self.aws_bucket             = yml["aws_bucket"] if yml.has_key?("aws_bucket")
      self.aws_region             = yml["aws_region"] if yml.has_key?("aws_region")
      self.existing_remote_files  = yml["existing_remote_files"] if yml.has_key?("existing_remote_files")
      self.gzip_compression       = yml["gzip_compression"] if yml.has_key?("gzip_compression")
      self.manifest               = yml["manifest"] if yml.has_key?("manifest")

      # TODO deprecate old style config settings
      self.aws_access_key         = yml["access_key_id"] if yml.has_key?("access_key_id")
      self.aws_access_secret      = yml["secret_access_key"] if yml.has_key?("secret_access_key")
      self.aws_bucket             = yml["bucket"] if yml.has_key?("bucket")
      self.aws_region             = yml["region"] if yml.has_key?("region")
    end

    def fog_options
      options = {
        :provider => provider, 
        :aws_access_key_id => aws_access_key,
        :aws_secret_access_key => aws_access_secret
      }
      options.merge!({:region => aws_region}) if aws_region
      return options
    end

  end
end
