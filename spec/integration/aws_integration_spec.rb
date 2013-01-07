require File.dirname(__FILE__) + '/../spec_helper'

def bucket
  options = {
    :provider => 'AWS',
    :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
  }

  connection = Fog::Storage.new(options)
  connection.directories.get(ENV['FOG_DIRECTORY'], :prefix => 'assets')
end

def execute(command)
  app_path = File.expand_path("../../dummy_app", __FILE__)
  Dir.chdir app_path
  `#{command}`
end

describe "AssetSync" do

  before(:each) do
    bucket.files.each do |f|
      f.destroy
    end
  end

  it "sync" do
    execute 'rake assets:precompile'
    bucket.files.size.should == 5
  end

  it "sync with enabled=false" do
    execute 'rake ASSET_SYNC_ENABLED=false assets:precompile'
    bucket.files.size.should == 0
  end

  it "sync with gzip_compression=true" do
    execute 'rake ASSET_SYNC_GZIP_COMPRESSION=true assets:precompile'
    bucket.files.size.should == 3
  end

end

