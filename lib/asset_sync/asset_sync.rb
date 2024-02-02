require "yaml"

module AssetSync

  class << self

    def config=(data)
      puts "INVOKING: #{self.class.name} => def config=(data)"
      @config = data
    end

    def config
      puts "INVOKING: #{self.class.name} => def config"
      @config ||= Config.new
      @config
    end

    def reset_config!
      puts "INVOKING: #{self.class.name} => def reset_config!"
      remove_instance_variable :@config if defined?(@config)
    end

    def configure(&proc)
      puts "INVOKING: #{self.class.name} => def configure(&proc)"
      @config ||= Config.new
      yield @config
    end

    def storage
      puts "INVOKING: #{self.class.name} => def storage"
      @storage ||= Storage.new(self.config)
    end

    def sync
      puts "INVOKING: #{self.class.name} => def sync"
      with_config do
        self.storage.sync
      end
    end

    def clean
      puts "INVOKING: #{self.class.name} => def clean"
      with_config do
        self.storage.delete_extra_remote_files
      end
    end

    def with_config(&block)
      puts "INVOKING: #{self.class.name} => def with_config(&block)"
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
      puts "INVOKING: #{self.class.name} => def warn(msg)"
      stderr.puts msg
    end

    def log(msg)
      puts "INVOKING: #{self.class.name} => def log(msg)"
      stdout.puts msg unless config.log_silently?
    end

    def load_yaml(yaml)
      puts "INVOKING: #{self.class.name} => def load_yaml(yaml)"
      if YAML.respond_to?(:unsafe_load)
        YAML.unsafe_load(yaml)
      else
        YAML.load(yaml)
      end
    end

    def enabled?
      puts "INVOKING: #{self.class.name} => def enabled?"
      config.enabled?
    end

    # easier to stub
    def stderr ; STDERR ; end
    puts "INVOKING: #{self.class.name} => def stderr ; STDERR ; end"
    def stdout ; STDOUT ; end
    puts "INVOKING: #{self.class.name} => def stdout ; STDOUT ; end"

  end

end
