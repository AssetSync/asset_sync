require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync do
  include_context "mock Rails without_yml"

  describe 'with initializer' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fog_provider = 'AzureRM'
        config.azure_storage_account_name = 'aaaa'
        config.azure_storage_access_key = 'bbbb'
        config.fog_directory = 'mybucket'
        config.existing_remote_files = "keep"
      end
    end

    it "should configure provider as AzureRM" do
      expect(AssetSync.config.fog_provider).to eq('AzureRM')
      expect(AssetSync.config).to be_azure_rm
    end

    it "should should keep existing remote files" do
      expect(AssetSync.config.existing_remote_files?).to eq(true)
    end

    it "should configure azure_storage_account_name" do
      expect(AssetSync.config.azure_storage_account_name).to eq("aaaa")
    end

    it "should configure azure_storage_access_key" do
      expect(AssetSync.config.azure_storage_access_key).to eq("bbbb")
    end

    it "should configure fog_directory" do
      expect(AssetSync.config.fog_directory).to eq("mybucket")
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

  describe 'from yml' do
    before(:each) do
      set_rails_root('azure_rm_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should configure azure_storage_account_name" do
      expect(AssetSync.config.azure_storage_account_name).to eq("xxxx")
    end

    it "should configure azure_storage_access_key" do
      expect(AssetSync.config.azure_storage_access_key).to eq("zzzz")
    end

    it "should configure fog_directory" do
      expect(AssetSync.config.fog_directory).to eq("rails_app_test")
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

  describe 'with no configuration' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
    end

    it "should be invalid" do
      expect{ AssetSync.sync }.to raise_error(::AssetSync::Config::Invalid)
    end
  end

  describe 'with fail_silent configuration' do
    before(:each) do
      allow(AssetSync).to receive(:stderr).and_return(StringIO.new)
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fail_silently = true
      end
    end

    it "should not raise an invalid exception" do
      expect{ AssetSync.sync }.not_to raise_error
    end
  end

  describe 'with gzip_compression enabled' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.config.gzip_compression = true
    end

    it "config.compression should be 'gz'" do
      expect(AssetSync.config.compression).to eq("gz")
    end
  end

  describe 'with manifest enabled' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.config.manifest = true
    end

    it "config.manifest should be true" do
      expect(AssetSync.config.manifest).to be_truthy
    end

    it "config.manifest_path should default to public/assets.." do
      expect(AssetSync.config.manifest_path).to match(/public\/assets\/manifest.yml/)
    end

    it "config.manifest_path should default to public/assets.." do
      Rails.application.config.assets.manifest = "/var/assets"
      expect(AssetSync.config.manifest_path).to eq("/var/assets/manifest.yml")
    end

    it "config.manifest_path should default to public/custom_assets.." do
      Rails.application.config.assets.prefix = 'custom_assets'
      expect(AssetSync.config.manifest_path).to match(/public\/custom_assets\/manifest.yml/)
    end
  end
end
