require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync do
  include_context "mock Rails without_yml"

  describe 'with initializer' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fog_provider = 'Google'
        config.google_storage_access_key_id = 'aaaa'
        config.google_storage_secret_access_key = 'bbbb'
        config.fog_directory = 'mybucket'
        config.existing_remote_files = "keep"
      end
    end

    it "should configure provider as Google" do
      AssetSync.config.fog_provider.should == 'Google'
      AssetSync.config.should be_google
    end

    it "should should keep existing remote files" do
      AssetSync.config.existing_remote_files?.should == true
    end

    it "should configure google_storage_access_key_id" do
      AssetSync.config.google_storage_access_key_id.should == "aaaa"
    end

    it "should configure google_storage_secret_access_key" do
      AssetSync.config.google_storage_secret_access_key.should == "bbbb"
    end

    it "should configure fog_directory" do
      AssetSync.config.fog_directory.should == "mybucket"
    end

    it "should configure existing_remote_files" do
      AssetSync.config.existing_remote_files.should == "keep"
    end

    it "should default gzip_compression to false" do
      AssetSync.config.gzip_compression.should be_false
    end

    it "should default manifest to false" do
      AssetSync.config.manifest.should be_false
    end
  end

  describe 'from yml' do
    before(:each) do
      set_rails_root('google_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should configure google_storage_access_key_id" do
      AssetSync.config.google_storage_access_key_id.should == "xxxx"
    end

    it "should configure google_storage_secret_access_key" do
      AssetSync.config.google_storage_secret_access_key.should == "zzzz"
    end

    it "should configure google_storage_access_key" do
      AssetSync.config.fog_directory.should == "rails_app_test"
    end

    it "should configure google_storage_access_key" do
      AssetSync.config.existing_remote_files.should == "keep"
    end

    it "should default gzip_compression to false" do
      AssetSync.config.gzip_compression.should be_false
    end

    it "should default manifest to false" do
      AssetSync.config.manifest.should be_false
    end
  end

  describe 'with no configuration' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
    end

    it "should be invalid" do
      lambda{ AssetSync.sync }.should raise_error(AssetSync::Config::Invalid)
    end
  end

  describe 'with fail_silent configuration' do
    before(:each) do
      AssetSync.stub(:stderr).and_return(StringIO.new)
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fail_silently = true
      end
    end

    it "should not raise an invalid exception" do
      lambda{ AssetSync.sync }.should_not raise_error(AssetSync::Config::Invalid)
    end
  end

  describe 'with gzip_compression enabled' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.config.gzip_compression = true
    end

    it "config.gzip? should be true" do
      AssetSync.config.gzip?.should be_true
    end
  end

  describe 'with manifest enabled' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.config.manifest = true
    end

    it "config.manifest should be true" do
      AssetSync.config.manifest.should be_true
    end

    it "config.manifest_path should default to public/assets.." do
      AssetSync.config.manifest_path.should =~ /public\/assets\/manifest.yml/
    end

    it "config.manifest_path should default to public/assets.." do
      Rails.application.config.assets.manifest = "/var/assets"
      AssetSync.config.manifest_path.should == "/var/assets/manifest.yml"
    end

    it "config.manifest_path should default to public/custom_assets.." do
      Rails.application.config.assets.prefix = 'custom_assets'
      AssetSync.config.manifest_path.should =~ /public\/custom_assets\/manifest.yml/
    end
  end
end
