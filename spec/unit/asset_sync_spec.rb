require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync do
  include_context "mock Rails without_yml"

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
      end
    end

    it "should default to running on precompile" do
      expect(AssetSync.config.run_on_precompile).to be_truthy
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

    it "should default gzip_compression to false" do
      expect(AssetSync.config.gzip_compression).to be_falsey
    end

    it "should default manifest to false" do
      expect(AssetSync.config.manifest).to be_falsey
    end

    it "should default log_silently to true" do
      expect(AssetSync.config.log_silently).to be_truthy
    end

    it "should default cdn_distribution_id to nil" do
      expect(AssetSync.config.cdn_distribution_id).to be_nil
    end

    it "should default invalidate to empty array" do
      expect(AssetSync.config.invalidate).to eq([])
    end
  end

  describe 'from yml' do
    before(:each) do
      set_rails_root('aws_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should default AssetSync to enabled" do
      expect(AssetSync.config.enabled?).to be_truthy
      expect(AssetSync.enabled?).to be_truthy
    end

    it "should configure run_on_precompile" do
      expect(AssetSync.config.run_on_precompile).to be_falsey
    end

    it "should configure aws_access_key_id" do
      expect(AssetSync.config.aws_access_key_id).to eq("xxxx")
    end

    it "should configure aws_secret_access_key" do
      expect(AssetSync.config.aws_secret_access_key).to eq("zzzz")
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

    it "should default gzip_compression to false" do
      expect(AssetSync.config.gzip_compression).to be_falsey
    end

    it "should default manifest to false" do
      expect(AssetSync.config.manifest).to be_falsey
    end
  end

  describe 'from yml, exporting to a mobile hybrid development directory' do
    before(:each) do
      Rails.env.replace('hybrid')
      set_rails_root('aws_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should be disabled" do
      expect{ AssetSync.sync }.not_to raise_error()
    end

    after(:each) do
      Rails.env.replace('test')
    end
  end

  describe 'with no configuration' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
    end

    it "should be invalid" do
      expect{ AssetSync.sync }.to raise_error()
    end
  end

  describe "with no other configuration than enabled = false" do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.enabled = false
      end
    end

    it "should do nothing, without complaining" do
      expect{ AssetSync.sync }.not_to raise_error()
    end
  end

  describe 'with fail_silent configuration' do
    before(:each) do
      allow(AssetSync).to receive(:stderr).and_return(@stderr = StringIO.new)
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fail_silently = true
      end
    end

    it "should not raise an invalid exception" do
      expect{ AssetSync.sync }.not_to raise_error()
    end

    it "should output a warning to stderr" do
      AssetSync.sync
      expect(@stderr.string).to match(/can't be blank/)
    end
  end

  describe 'with disabled config' do
    before(:each) do
      allow(AssetSync).to receive(:stderr).and_return(@stderr = StringIO.new)
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.enabled = false
      end
    end

    it "should not raise an invalid exception" do
      expect{ AssetSync.sync }.not_to raise_error()
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

  describe 'with invalid yml' do

    before(:each) do
      set_rails_root('with_invalid_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "config should be invalid" do
      expect(AssetSync.config.valid?).to be_falsey
    end

    it "should raise a config invalid error" do
      expect{ AssetSync.sync }.to raise_error()
    end
  end
end
