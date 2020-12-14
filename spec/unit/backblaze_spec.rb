require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync do
  include_context "mock Rails without_yml"

  describe 'with initializer' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fog_provider = 'Backblaze'
        config.b2_key_id = 'aaaa'
        config.b2_key_token = 'bbbb'
        config.b2_bucket_id = '4567'
        config.fog_directory = 'mybucket'
        config.existing_remote_files = "keep"
      end
    end

    it "should configure provider as Backblaze" do
      expect(AssetSync.config.fog_provider).to eq('Backblaze')
    end

    it "should should keep existing remote files" do
      expect(AssetSync.config.existing_remote_files?).to eq(true)
    end

    it "should configure b2_key_id" do
      expect(AssetSync.config.b2_key_id).to eq("aaaa")
    end

    it "should configure b2_key_token" do
      expect(AssetSync.config.b2_key_token).to eq("bbbb")
    end

    it "should configure b2_bucket_id" do
      expect(AssetSync.config.b2_bucket_id).to eq("4567")
    end

    it "should configure fog_directory" do
      expect(AssetSync.config.fog_directory).to eq("mybucket")
    end

    it "should configure existing_remote_files" do
      expect(AssetSync.config.existing_remote_files).to eq("keep")
    end

    it "should default gzip_compression to false" do
      expect(AssetSync.config.gzip_compression).to be_falsey
    end

    it "should default manifest to false" do
      expect(AssetSync.config.manifest).to be_falsey
    end
  end

  describe 'from yml' do
    before(:each) do
      set_rails_root('backblaze_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should configure b2_key_id" do
      expect(AssetSync.config.b2_key_id).to eq("xxxx")
    end

    it "should configure b2_key_token" do
      expect(AssetSync.config.b2_key_token).to eq("zzzz")
    end

    it "should configure b2_bucket_id" do
      expect(AssetSync.config.b2_bucket_id).to eq("1234")
    end

    it "should configure fog_directory" do
      expect(AssetSync.config.fog_directory).to eq("rails_app_test")
    end

    it "should configure existing_remote_files" do
      expect(AssetSync.config.existing_remote_files).to eq("keep")
    end

    it "should default gzip_compression to false" do
      expect(AssetSync.config.gzip_compression).to be_falsey
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

    it "config.gzip? should be true" do
      expect(AssetSync.config.gzip?).to be_truthy
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
