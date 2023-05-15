require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync do
  include_context "mock without Rails"

  describe 'with initializer' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fog_provider = 'AWS'
        config.aws_access_key_id = 'aaaa'
        config.aws_secret_access_key = 'bbbb'
        config.fog_directory = 'mybucket'
        config.fog_region = 'eu-west-1'
        config.existing_remote_files = "keep"
        config.prefix = "assets"
        config.public_path = "./public"
      end
    end

    it "should have prefix of assets" do
      expect(AssetSync.config.prefix).to eq("assets")
    end

    it "should have public_path" do
      expect(AssetSync.config.public_path.to_s).to be_end_with("/public")
      expect(AssetSync.config.public_path).to be_absolute
    end

    it "should default AssetSync to enabled" do
      expect(AssetSync.config.enabled?).to be_truthy
      expect(AssetSync.enabled?).to be_truthy
    end

    it "should configure provider as AWS" do
      expect(AssetSync.config.fog_provider).to eq('AWS')
      expect(AssetSync.config).to be_aws
    end

    it "should should keep existing remote files" do
      expect(AssetSync.config.existing_remote_files?).to eq(true)
    end

    it "should configure aws_access_key" do
      expect(AssetSync.config.aws_access_key_id).to eq("aaaa")
    end

    it "should configure aws_secret_access_key" do
      expect(AssetSync.config.aws_secret_access_key).to eq("bbbb")
    end

    it "should configure aws_access_key" do
      expect(AssetSync.config.fog_directory).to eq("mybucket")
    end

    it "should configure fog_region" do
      expect(AssetSync.config.fog_region).to eq("eu-west-1")
    end

    it "should configure existing_remote_files" do
      expect(AssetSync.config.existing_remote_files).to eq("keep")
    end

    it "should default compression to nil" do
      expect(AssetSync.config.compression).to be_nil
    end

    it "should default manifest to false" do
      expect(AssetSync.config.manifest).to be_falsey
    end

  end
end
