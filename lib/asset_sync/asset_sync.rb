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
        self.warn config.errors.full_messages.join(', ') unless config && config.valid?
      else
        raise Config::Invalid.new(config.errors.full_messages.join(', ')) unless config && config.valid?
      end
      self.storage.sync if config && config.valid?
    end

    def warn(msg)
      STDERR.puts msg
    end

    def log(msg)
      STDOUT.puts msg if ENV["RAILS_GROUPS"] == "assets"
    end

  end

end