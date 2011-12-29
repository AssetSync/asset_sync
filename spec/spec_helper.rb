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

RSpec.configure do |config|
  config.mock_framework = :rspec
end

shared_context "mock Rails" do
  before(:each) do
    unless defined? Rails
      Rails = mock 'Rails'
    end
    Rails.stub(:env).and_return('test')
    Rails.stub :application => mock('application')
    Rails.application.stub :config => mock('config')
    Rails.application.config.stub :assets => ActiveSupport::OrderedOptions.new
    Rails.application.config.assets.prefix = '/assets'
  end
end

shared_context "mock Rails without_yml" do
  include_context "mock Rails"

  before(:each) do
    set_rails_root('without_yml')
  end
end

def set_rails_root(path)
  Rails.stub(:root).and_return(File.join(File.dirname(__FILE__), path))
end
