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
      if config.fail_silently?
        self.log config.errors.full_messages.join(', ') unless config && config.valid?
      else
        raise Config::Invalid.new(config.errors.full_messages.join(', ')) unless config && config.valid?
      end
      self.storage.sync if config && config.valid?
    end

  private

    def log(msg)
      STDERR.puts msg
    end

  end

end