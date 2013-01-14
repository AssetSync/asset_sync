require 'rubygems'
require 'bundler'

if RUBY_VERSION != '1.8.7'
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

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

require 'rspec'
RSpec.configure do |config|
  config.mock_framework = :rspec
end

shared_context "mock without Rails" do
  before(:each) do
    if defined? Rails
      Object.send(:remove_const, :Rails)
    end
    AssetSync.stub!(:log)
  end
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
    AssetSync.stub!(:log)
  end
end

shared_context "mock Rails without_yml" do
  include_context "mock Rails"

  before(:each) do
    set_rails_root('without_yml')
    Rails.stub(:public_path).and_return(Rails.root.join('public').to_s)
  end
end

def set_rails_root(path)
  Rails.stub(:root).and_return(Pathname.new(File.join(File.dirname(__FILE__), 'fixtures', path)))
end
