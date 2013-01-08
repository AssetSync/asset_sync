require File.dirname(__FILE__) + '/../spec_helper'

def bucket(name)
  options = {
    :provider => 'AWS',
    :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
  }

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

  after(:each) do
    @directory = bucket(@prefix)
    @directory.files.each do |f|
      f.destroy
    end
  end

  it "sync" do
    execute "rake ASSET_SYNC_PREFIX=#{@prefix} assets:precompile"
    bucket(@prefix).files.size.should == 5

    app_js = bucket(@prefix).files.get("#{@prefix}/application.js")
    app_js.content_type.should == "text/javascript"

    app_js_gz = bucket(@prefix).files.get("#{@prefix}/application.js.gz")
    app_js_gz.content_type.should == "text/javascript"
    app_js_gz.content_encoding.should == "gzip"
  end

  it "sync with enabled=false" do
    execute "rake ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_ENABLED=false assets:precompile"
    bucket(@prefix).files.size.should == 0
  end

  it "sync with gzip_compression=true" do
    execute "rake ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_GZIP_COMPRESSION=true assets:precompile"
    bucket(@prefix).files.size.should == 3

    app_js = bucket(@prefix).files.get("#{@prefix}/application.js")
    app_js.content_type.should == "text/javascript"
  end

end

