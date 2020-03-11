module AssetSync
  class Engine < Rails::Engine

    engine_name "asset_sync"

    initializer "asset_sync config", :group => :all do |app|
      app_initializer = Rails.root.join('config', 'initializers', 'asset_sync.rb').to_s
      app_yaml = Rails.root.join('config', 'asset_sync.yml').to_s

      if File.exist?( app_initializer )
        AssetSync.log "AssetSync: using #{app_initializer}"
        load app_initializer
      elsif !File.exist?( app_initializer ) && !File.exist?( app_yaml )
        AssetSync.log "AssetSync: using default configuration from built-in initializer"
        AssetSync.configure do |config|
          config.fog_provider = ENV['FOG_PROVIDER'] if ENV.has_key?('FOG_PROVIDER')
          config.fog_directory = ENV['FOG_DIRECTORY'] if ENV.has_key?('FOG_DIRECTORY')
          config.fog_region = ENV['FOG_REGION'] if ENV.has_key?('FOG_REGION')
          config.fog_host = ENV['FOG_HOST'] if ENV.has_key?('FOG_HOST')
          config.fog_port = ENV['FOG_PORT'] if ENV.has_key?('FOG_PORT')
          config.fog_scheme = ENV['FOG_SCHEMA'] if ENV.has_key?('FOG_SCHEMA')
          config.fog_path_style = ENV['FOG_PATH_STYLE'] if ENV.has_key?('FOG_PATH_STYLE')

          config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID'] if ENV.has_key?('AWS_ACCESS_KEY_ID')
          config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] if ENV.has_key?('AWS_SECRET_ACCESS_KEY')
          config.aws_signature_version = ENV['AWS_SIGNATURE_VERSION'] if ENV.has_key?('AWS_SIGNATURE_VERSION')
          config.aws_reduced_redundancy = ENV['AWS_REDUCED_REDUNDANCY'] == true  if ENV.has_key?('AWS_REDUCED_REDUNDANCY')

          config.rackspace_username = ENV['RACKSPACE_USERNAME'] if ENV.has_key?('RACKSPACE_USERNAME')
          config.rackspace_api_key = ENV['RACKSPACE_API_KEY'] if ENV.has_key?('RACKSPACE_API_KEY')

          config.google_storage_access_key_id = ENV['GOOGLE_STORAGE_ACCESS_KEY_ID'] if ENV.has_key?('GOOGLE_STORAGE_ACCESS_KEY_ID')
          config.google_storage_secret_access_key = ENV['GOOGLE_STORAGE_SECRET_ACCESS_KEY'] if ENV.has_key?('GOOGLE_STORAGE_SECRET_ACCESS_KEY')

          config.azure_storage_account_name = ENV['AZURE_STORAGE_ACCOUNT_NAME'] if ENV.has_key?('AZURE_STORAGE_ACCOUNT_NAME')
          config.azure_storage_access_key = ENV['AZURE_STORAGE_ACCESS_KEY'] if ENV.has_key?('AZURE_STORAGE_ACCESS_KEY')

          config.enabled = (ENV['ASSET_SYNC_ENABLED'] == 'true') if ENV.has_key?('ASSET_SYNC_ENABLED')

          config.existing_remote_files = ENV['ASSET_SYNC_EXISTING_REMOTE_FILES'] || "keep"

          config.gzip_compression = (ENV['ASSET_SYNC_GZIP_COMPRESSION'] == 'true') if ENV.has_key?('ASSET_SYNC_GZIP_COMPRESSION')
          config.manifest = (ENV['ASSET_SYNC_MANIFEST'] == 'true') if ENV.has_key?('ASSET_SYNC_MANIFEST')
          config.include_manifest = (ENV['ASSET_SYNC_INCLUDE_MANIFEST'] == 'true') if ENV.has_key?('ASSET_SYNC_INCLUDE_MANIFEST')
          config.concurrent_uploads = (ENV['ASSET_SYNC_CONCURRENT_UPLOADS'] == 'true') if ENV.has_key?('ASSET_SYNC_CONCURRENT_UPLOADS')
          config.remote_file_list_cache_file_path = ENV['ASSET_SYNC_REMOTE_FILE_LIST_CACHE_FILE_PATH'] if ENV.has_key?('ASSET_SYNC_REMOTE_FILE_LIST_CACHE_FILE_PATH')
        end

        config.prefix = ENV['ASSET_SYNC_PREFIX'] if ENV.has_key?('ASSET_SYNC_PREFIX')

        config.existing_remote_files = ENV['ASSET_SYNC_EXISTING_REMOTE_FILES'] || "keep"

        config.gzip_compression = (ENV['ASSET_SYNC_GZIP_COMPRESSION'] == 'true') if ENV.has_key?('ASSET_SYNC_GZIP_COMPRESSION')
        config.manifest = (ENV['ASSET_SYNC_MANIFEST'] == 'true') if ENV.has_key?('ASSET_SYNC_MANIFEST')

      end

      if File.exist?( app_yaml )
        AssetSync.log "AssetSync: YAML file found #{app_yaml} settings will be merged into the configuration"
      end
    end

  end
end
