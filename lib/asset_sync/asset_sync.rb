module AssetSync

  class << self

    def config=(data)
      @config = data
    end

    def config
      @config ||= Config.new
      raise Config::Invalid("Your configuration in (config/asset_sync.yml or config/initializers/asset_sync.rb) is missing or invalid, please refer to the documention and emend") unless @config && @config.valid?
      @config
    end

    def configure(&proc)
      @config ||= Config.new
      yield @config
    end

    def storage
      @storage ||= Storage.new(self.config)
    end

    def sync
      self.storage.sync
    end

  end

end
