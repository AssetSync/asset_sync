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
      return unless AssetSync.enabled?

      errors = config.valid? ? "" : config.errors.full_messages.join(', ')

      if !(config && config.valid?)
        if config.fail_silently?
          self.warn(errors)
        else
          raise Config::Invalid.new(errors)
        end
      else
        self.storage.sync
      end
    end

    def warn(msg)
      stderr.puts msg
    end

    def log(msg)
      stdout.puts msg if ENV["RAILS_GROUPS"] == "assets"
    end

    def enabled?
      config.enabled?
    end

    # easier to stub
    def stderr ; STDERR ; end
    def stdout ; STDOUT ; end

  end

end
