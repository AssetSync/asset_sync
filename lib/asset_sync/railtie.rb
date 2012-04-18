class Rails::Railtie::Configuration
  def asset_sync
    AssetSync.config
  end
end