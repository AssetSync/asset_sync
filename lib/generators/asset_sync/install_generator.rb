require 'rails/generators'
module AssetSync
  class InstallGenerator < Rails::Generators::Base
    desc "Install a config/asset_sync.yml and the asset:precompile rake task enhancer"

    # Commandline options can be defined here using Thor-like options:
    class_option :my_opt, :type => :boolean, :default => false, :desc => "My Option"

    # I can later access that option using:
    # options[:my_opt]

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def aws_access_key
      "<%= ENV['AWS_ACCESS_KEY'] %>"
    end

    def aws_access_secret
      "<%= ENV['AWS_ACCESS_SECRET'] %>"
    end

    def app_name
      @app_name ||= Rails.application.is_a?(Rails::Application) && Rails.application.class.name.sub(/::Application$/, "").downcase
    end

    def generate_config
      template "asset_sync.yml", "config/asset_sync.yml"
    end
    
    def generate_rake_task
      template "asset_sync.rake", "lib/tasks/asset_sync.rake"
    end
  end
end
