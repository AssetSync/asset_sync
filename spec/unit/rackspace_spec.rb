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
      expect(AssetSync.config.fog_provider).to eq('Rackspace')
      expect(AssetSync.config).to be_rackspace
    end

    it "should keep existing remote files" do
      expect(AssetSync.config.existing_remote_files?).to eq(true)
    end

    it "should configure rackspace_username" do
      expect(AssetSync.config.rackspace_username).to eq("aaaa")
    end

    it "should configure rackspace_api_key" do
      expect(AssetSync.config.rackspace_api_key).to eq("bbbb")
    end

    it "should configure fog_directory" do
      expect(AssetSync.config.fog_directory).to eq("mybucket")
    end

    it "should configure fog_region" do
      expect(AssetSync.config.fog_region).to eq("dunno")
    end

    it "should configure existing_remote_files" do
      expect(AssetSync.config.existing_remote_files).to eq("keep")
    end

    it "should configure existing_remote_files" do
      expect(AssetSync.config.existing_remote_files).to eq("keep")
    end

    it "should default rackspace_auth_url to false" do
      expect(AssetSync.config.rackspace_auth_url).to be_falsey
    end

  end

  describe 'using Rackspace from yml' do

    before(:each) do
      set_rails_root('rackspace_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should keep existing remote files" do
      expect(AssetSync.config.existing_remote_files?).to eq(true)
    end

    it "should configure rackspace_username" do
      expect(AssetSync.config.rackspace_username).to eq("xxxx")
    end

    it "should configure rackspace_api_key" do
      expect(AssetSync.config.rackspace_api_key).to eq("zzzz")
    end

    it "should configure fog_directory" do
      expect(AssetSync.config.fog_directory).to eq("rails_app_test")
    end

    it "should configure fog_region" do
      expect(AssetSync.config.fog_region).to eq("eu-west-1")
    end

    it "should configure existing_remote_files" do
      expect(AssetSync.config.existing_remote_files).to eq("keep")
    end
  end
end
