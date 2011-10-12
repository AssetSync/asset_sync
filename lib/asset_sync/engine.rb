class Engine < Rails::Engine

  engine_name "asset_sync"

  initializer "asset_sync config", :group => :assets do |app|
    app_initializer = File.join(Rails.root, 'config/initializers/asset_sync.rb')
    app_yaml = File.join(Rails.root, 'config/asset_sync.yml')

    if File.exists?( app_initializer )
      load app_initializer
    # elsif File.exists?( app_yaml )
    # do nothing as yaml will be loaded on initialize of AssetSync
    else
      AssetSync.configure do |config|
        config.aws_access_key = ENV['AWS_ACCESS_KEY']
        config.aws_access_secret = ENV['AWS_ACCESS_SECRET']
        config.aws_bucket = ENV['AWS_BUCKET']
        config.existing_remote_files = "keep"
      end
    end

  end

end