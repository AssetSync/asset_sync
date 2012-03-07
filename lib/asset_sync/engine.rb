class Engine < Rails::Engine

  engine_name "asset_sync"

  initializer "asset_sync config", :group => :all do |app|
    app_initializer = File.join(Rails.root, 'config/initializers/asset_sync.rb')
    app_yaml = File.join(Rails.root, 'config/asset_sync.yml')

    if File.exists?( app_initializer )
      # STDERR.puts "AssetSync: using #{app_initializer}"
      load app_initializer
    elsif !File.exists?( app_initializer ) && !File.exists?( app_yaml )
      # STDERR.puts "AssetSync: using default configuration from built-in initializer"
      AssetSync.configure do |config|
        config.fog_provider = ENV['FOG_PROVIDER']
        config.fog_directory = ENV['FOG_DIRECTORY']
        config.fog_region = ENV['FOG_REGION']

        config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
        config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

        config.rackspace_username = ENV['RACKSPACE_USERNAME']
        config.rackspace_api_key = ENV['RACKSPACE_API_KEY']
        config.existing_remote_files = ENV['ASSET_SYNC_EXISTING_REMOTE_FILES'] || "keep"
        config.gzip_compression = ENV['ASSET_SYNC_GZIP_COMPRESSION'] == 'true'
        config.manifest = ENV['ASSET_SYNC_MANIFEST'] == 'true'
      end
    end

    # if File.exists?( app_yaml )
    # STDERR.puts "AssetSync: YAML file found #{app_yaml} settings will be merged into the configuration"
    # end
  end

end
