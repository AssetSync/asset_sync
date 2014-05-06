require 'fog' unless defined?(::Fog)
require 'active_model'
require 'erb'
require "asset_sync/asset_sync"
require 'asset_sync/config'
require 'asset_sync/storage'
require 'asset_sync/multi_mime'


require 'asset_sync/railtie' if defined?(Rails)
require 'asset_sync/engine'  if defined?(Rails)
