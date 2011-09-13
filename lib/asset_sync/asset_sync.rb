module AssetSync

  class << self

    def config=(data)
      @config = data
    end

    def config
      @config ||= Config.new
      raise Config::Invalid.new(@config.errors.full_messages.join(', ')) unless @config && @config.valid?
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
