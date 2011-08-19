module AssetSync
  class Config

    class Invalid < StandardError; end

    attr_accessor :provider
    attr_accessor :aws_access_key, :aws_access_secret
    attr_accessor :aws_bucket
    attr_accessor :existing_remote_files
    attr_accessor :region

    def initialize
      self.provider = 'AWS'
      self.region = nil
      load_yml! if yml_exists?
    end

    def yml_exists?
      File.exists?(self.yml_path)
    end

    def yml
      y ||= YAML.load(ERB.new(IO.read(yml_path)).result)[Rails.env] rescue nil || {}
      HashWithIndifferentAccess.new(y)
    end

    def yml_path
      File.join(Rails.root, "config/asset_sync.yml")
    end

    def load_yml!
      self.aws_access_key = yml[:aws_access_key]
      self.aws_access_secret = yml[:aws_access_secret]
      self.aws_bucket = yml[:aws_bucket]
      self.region = yml[:aws_bucket]

      # TODO deprecate old style config settings
      self.aws_access_key = yml[:access_key_id] if yml.has_key?(:access_key_id)
      self.aws_access_secret = yml[:secret_access_key] if yml.has_key?(:secret_access_key)
      self.aws_bucket = yml[:bucket] if yml.has_key?(:bucket)
    end

    def fog_options
      storage = {
        :provider => provider, 
        :aws_access_key_id => aws_access_key,
        :aws_secret_access_key => aws_access_secret
      }
      storage.merge!({:region => region}) if region
      return storage
    end

    def valid?
      true
    end

  end
end
