require File.dirname(__FILE__) + '/spec_helper'


describe AssetSync, 'with initializer' do

  before(:all) do
    Rails.root = 'without_yml'
    AssetSync.config = AssetSync::Config.new
    AssetSync.configure do |config|
      config.fog_provider = 'AWS'
      config.aws_access_key_id = 'aaaa'
      config.aws_secret_access_key = 'bbbb'
      config.fog_directory = 'mybucket'
      config.fog_region = 'eu-west-1'
      config.existing_remote_files = "keep"
    end
  end

  it "should configure provider as AWS" do
    AssetSync.config.fog_provider.should == 'AWS'
    AssetSync.config.should be_aws
  end

  it "should should keep existing remote files" do
    AssetSync.config.existing_remote_files?.should == true
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_access_key_id.should == "aaaa"
  end

  it "should configure aws_access_key" do
    AssetSync.config.aws_secret_access_key.should == "bbbb"
  end

  it "should configure aws_access_key" do
    AssetSync.config.fog_directory.should == "mybucket"
  end

  it "should configure aws_access_key" do
    AssetSync.config.fog_region.should == "eu-west-1"
  end

  it "should configure aws_access_key" do
    AssetSync.config.existing_remote_files.should == "keep"
  end

end


describe AssetSync, 'from yml' do

  before(:all) do
    Rails.root = 'aws_with_yml'
    AssetSync.config = AssetSync::Config.new
  end

  it "should configure aws_access_key_id" do
    AssetSync.config.aws_access_key_id.should == "xxxx"
  end

  it "should configure aws_secret_access_key" do
    AssetSync.config.aws_secret_access_key.should == "zzzz"
  end

  it "should configure aws_access_key" do
    AssetSync.config.fog_directory.should == "rails_app_test"
  end

  it "should configure aws_access_key" do
    AssetSync.config.fog_region.should == "eu-west-1"
  end

  it "should configure aws_access_key" do
    AssetSync.config.existing_remote_files.should == "keep"
  end

end

describe AssetSync, 'with no configuration' do

  before(:all) do
    Rails.root = 'without_yml'
    AssetSync.config = AssetSync::Config.new
  end

  it "should be invalid" do
    lambda{ AssetSync.sync }.should raise_error(AssetSync::Config::Invalid)
  end

end