module AssetSync

  class << self

    def config=(data)
      @config = data
    end

    def config
      @config ||= Config.new
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
      raise Config::Invalid.new(config.errors.full_messages.join(', ')) unless config && config.valid?
      self.storage.sync
    end

  end

end