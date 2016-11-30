require 'fog/core'
require 'active_model'
require 'erb'
require "asset_sync/asset_sync"
require 'asset_sync/config'
require 'asset_sync/storage'
require 'asset_sync/multi_mime'


if defined?(Rails)
  require 'asset_sync/railtie'
  require 'asset_sync/engine'
end
