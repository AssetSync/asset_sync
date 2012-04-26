require 'rails/generators'
module AssetSync
  class InstallGenerator < Rails::Generators::Base
    desc "Install a config/asset_sync.yml and the asset:precompile rake task enhancer"

    # Commandline options can be defined here using Thor-like options:
    class_option :use_yml,   :type => :boolean, :default => false, :desc => "Use YML file instead of Rails Initializer"
    class_option :provider,  :type => :string,  :default => "AWS",  :desc => "Generate with support for 'AWS', 'Rackspace', or 'Google'"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def aws?
      options[:provider] == 'AWS'
    end

    def google?
      options[:provider] == 'Google'
    end

    def rackspace?
      options[:provider] == 'Rackspace'
    end

    def aws_access_key_id
      "<%= ENV['AWS_ACCESS_KEY_ID'] %>"
    end

    def aws_secret_access_key
      "<%= ENV['AWS_SECRET_ACCESS_KEY'] %>"
    end

    def google_storage_access_key_id
      "<%= ENV['GOOGLE_STORAGE_ACCESS_KEY_ID'] %>"
    end

    def google_storage_secret_access_key
      "<%= ENV['GOOGLE_STORAGE_SECRET_ACCESS_KEY'] %>"
    end

    def rackspace_username
      "<%= ENV['RACKSPACE_USERNAME'] %>"
    end

    def rackspace_api_key
      "<%= ENV['RACKSPACE_API_KEY'] %>"
    end

    def app_name
      @app_name ||= Rails.application.is_a?(Rails::Application) && Rails.application.class.name.sub(/::Application$/, "").downcase
    end

    def generate_config
      if options[:use_yml]
        template "asset_sync.yml", "config/asset_sync.yml"
      end
    end

    def generate_initializer
      unless options[:use_yml]
        template "asset_sync.rb", "config/initializers/asset_sync.rb"
      end
    end

  end
end
