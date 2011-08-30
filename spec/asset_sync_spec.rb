require File.dirname(__FILE__) + '/spec_helper'


describe AssetSync, 'with initializer' do

  before(:all) do
    Rails.root = 'without_yml'
    AssetSync.config = AssetSync::Config.new
    AssetSync.configure do |config|
      config.aws_access_key = 'aaaa'
      config.aws_access_secret = 'bbbb'
      config.aws_bucket = 'mybucket'
      config.aws_region = 'eu-west-1'
      config.existing_remote_files = "keep"
    end
  end

  it "should should keep existing remote files" do
    AssetSync.config.existing_remote_files?.should == true
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_access_key.should == "aaaa"
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_access_secret.should == "bbbb"
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_bucket.should == "mybucket"
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_region.should == "eu-west-1"
  end

  it "should configure aws_access_key" do
    AssetSync.config.existing_remote_files.should == "keep"
  end

end


describe AssetSync, 'from yml' do

  before(:all) do
    Rails.root = 'with_yml'
    AssetSync.config = AssetSync::Config.new
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_access_key.should == "xxxx"
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_access_secret.should == "zzzz"
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_bucket.should == "rails_app_test"
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_region.should == "eu-west-1"
  end

  it "should configure aws_access_key" do
    AssetSync.config.existing_remote_files.should == "keep"
  end

end
