require 'rubygems'
require 'bundler'

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
rescue LoadError
  # SimpleCov ain't available - continue
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
    allow(AssetSync).to receive(:log)
  end
end


shared_context "mock Rails" do
  before(:each) do
    Object.send(:remove_const, :Rails) if defined? Rails
    Rails = double 'Rails'
    allow(Rails).to receive(:env).and_return('test')
    allow(Rails).to receive_messages :application => double('application')
    allow(Rails.application).to receive_messages :config => double('config')
    allow(Rails.application.config).to receive_messages :assets => ActiveSupport::OrderedOptions.new
    Rails.application.config.assets.prefix = '/assets'
    allow(AssetSync).to receive(:log)
  end
end

shared_context "mock Rails without_yml" do
  include_context "mock Rails"

  before(:each) do
    set_rails_root('without_yml')
    allow(Rails).to receive(:public_path).and_return(Rails.root.join('public').to_s)
  end
end

def set_rails_root(path)
  allow(Rails).to receive(:root).and_return(Pathname.new(File.join(File.dirname(__FILE__), 'fixtures', path)))
end
