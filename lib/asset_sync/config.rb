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
      File.exists?(yml_path)
    end

    def yml_path
      File.join(Rails.root, "config/asset_sync.yml")
    end

    def from_yml
      yml = YAML.load(ERB.new(IO.read(yml_path)).result)[Rails.env] rescue nil || {}
      aws_access_key = yml[:aws_access_key]
      aws_access_secret = yml[:aws_access_secret]
      aws_bucket = yml[:aws_bucket]
      region = yml[:aws_bucket]

      # TODO deprecate old style config settings
      aws_access_key = yml[:aws_access_key_id]
      aws_access_secret = yml[:aws_secret_access_key]
    end

    def fog_options
      storage = {
        :provider => provider, 
        :aws_access_key_id => aws_access_key,
        :aws_secret_access_key => aws_access_secret
      }
      storage.merge!({:region => region) if region
      return storage
    end

    def valid?
      true
    end

  end
end
