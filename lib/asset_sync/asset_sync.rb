module AssetSync

  class << self

    def config=(data)
      @config = data
    end

    def config
      @config ||= Config.new
      @config
    end

    def reset_config!
      remove_instance_variable :@config if defined?(@config)
    end

    def configure(&proc)
      @config ||= Config.new
      yield @config
    end

    def storage
      @storage ||= Storage.new(self.config)
    end

    def sync
      with_config do
        self.storage.sync
      end
    end

    def clean
      with_config do
        self.storage.delete_extra_remote_files
      end
    end

    def with_config(&block)
      return unless AssetSync.enabled?

      errors = config.valid? ? "" : config.errors.full_messages.join(', ')

      if !(config && config.valid?)
        if config.fail_silently?
          self.warn(errors)
        else
          raise Config::Invalid.new(errors)
        end
      else
        block.call
      end
    end

    def warn(msg)
      stderr.puts msg
    end

    def log(msg)
      stdout.puts msg if config.log_silently?
    end

    def enabled?
      config.enabled?
    end

    # easier to stub
    def stderr ; STDERR ; end
    def stdout ; STDOUT ; end

  end

end
