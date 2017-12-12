require File.dirname(__FILE__) + '/../spec_helper'
require "fog/azurerm"

def bucket(name)
  options = {
    :provider => 'AzureRM',
    :azure_storage_account_name => ENV['AZURE_STORAGE_ACCOUNT_NAME'],
    :azure_storage_access_key => ENV['AZURE_STORAGE_ACCESS_KEY']
  }
  options.merge!({ :environment => ENV['FOG_REGION'] }) if ENV.has_key?('FOG_REGION')

  connection = Fog::Storage.new(options)
  connection.directories.get(ENV['FOG_DIRECTORY'], :prefix => name)
end

def execute(command)
  app_path = File.expand_path("../../dummy_app", __FILE__)
  Dir.chdir app_path
  `#{command}`
end

describe "AssetSync" do

  before(:each) do
    @prefix = SecureRandom.hex(6)
  end

  let(:app_js_regex){
    /#{@prefix}\/application-[a-zA-Z0-9]*.js$/
  }

  let(:app_js_gz_regex){
    /#{@prefix}\/application-[a-zA-Z0-9]*.js.gz$/
  }

  let(:files){ bucket(@prefix).files }


  after(:each) do
    @directory = bucket(@prefix)
    @directory.files.each do |f|
      f.destroy
    end
  end

  it "sync" do
    execute "rake ASSET_SYNC_PREFIX=#{@prefix} assets:precompile"

    files = bucket(@prefix).files

    app_js = files.select{ |f| f.key =~ app_js_regex }.first
    expect(app_js.content_type).to eq("application/javascript")

    app_js_gz = files.select{ |f| f.key =~ app_js_gz_regex }.first
    expect(app_js_gz.content_type).to eq("application/javascript")
    expect(app_js_gz.content_encoding).to eq("gzip")
  end

  it "sync with enabled=false" do
    execute "rake ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_ENABLED=false assets:precompile"
    expect(bucket(@prefix).files.size).to eq(0)
  end

  it "sync with gzip_compression=true" do
    execute "rake ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_GZIP_COMPRESSION=true assets:precompile"
    # bucket(@prefix).files.size.should == 3

    app_js_path = files.select{ |f| f.key =~ app_js_regex }.first
    app_js = files.get( app_js_path.key )
    expect(app_js.content_type).to eq("application/javascript")
  end

end

