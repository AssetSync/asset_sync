require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync do
  include_context "mock Rails"

  describe 'using Rackspace with initializer' do
    before(:each) do
      set_rails_root('without_yml')
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fog_provider          = 'Rackspace'
        config.fog_directory         = 'mybucket'
        config.fog_region            = 'dunno'
        config.rackspace_username    = 'aaaa'
        config.rackspace_api_key     = 'bbbb'
        config.existing_remote_files = 'keep'
      end
    end

    it "should configure provider as Rackspace" do
      AssetSync.config.fog_provider.should == 'Rackspace'
      AssetSync.config.should be_rackspace
    end

    it "should keep existing remote files" do
      AssetSync.config.existing_remote_files?.should == true
    end

    it "should configure rackspace_username" do
      AssetSync.config.rackspace_username.should == "aaaa"
    end

    it "should configure rackspace_api_key" do
      AssetSync.config.rackspace_api_key.should == "bbbb"
    end

    it "should configure fog_directory" do
      AssetSync.config.fog_directory.should == "mybucket"
    end

    it "should configure fog_region" do
      AssetSync.config.fog_region.should == "dunno"
    end

    it "should configure existing_remote_files" do
      AssetSync.config.existing_remote_files.should == "keep"
    end

    it "should configure existing_remote_files" do
      AssetSync.config.existing_remote_files.should == "keep"
    end

    it "should default rackspace_auth_url to false" do
      AssetSync.config.rackspace_auth_url.should be_false
    end

  end

  describe 'using Rackspace from yml' do

    before(:each) do
      set_rails_root('rackspace_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should keep existing remote files" do
      AssetSync.config.existing_remote_files?.should == true
    end

    it "should configure rackspace_username" do
      AssetSync.config.rackspace_username.should == "xxxx"
    end

    it "should configure rackspace_api_key" do
      AssetSync.config.rackspace_api_key.should == "zzzz"
    end

    it "should configure fog_directory" do
      AssetSync.config.fog_directory.should == "rails_app_test"
    end

    it "should configure fog_region" do
      AssetSync.config.fog_region.should == "eu-west-1"
    end

    it "should configure existing_remote_files" do
      AssetSync.config.existing_remote_files.should == "keep"
    end
  end
end
