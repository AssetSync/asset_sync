require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'asset_sync'

class Rails

  @@path = 'without_yml'

  def self.env
    "test"
  end

  def self.root=(path)
    @@path = path
  end

  def self.root
    File.expand_path(File.join('spec', @@path))
  end

end