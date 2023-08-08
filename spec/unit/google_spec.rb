require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync do
  include_context "mock Rails without_yml"

  describe 'with initializer' do
    before(:each) do
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fog_provider = 'Google'
        config.fog_directory = 'mybucket'
        config.existing_remote_files = "keep"
      end
    end

    it "should configure provider as Google" do
      expect(AssetSync.config.fog_provider).to eq('Google')
      expect(AssetSync.config).to be_google
    end

    it "should should keep existing remote files" do
      expect(AssetSync.config.existing_remote_files?).to eq(true)
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

    describe "when using user-specified google credentials" do
      before(:each) do
        AssetSync.configure do |config|
          config.google_auth = "access-token"
          config.google_project = 'a-google-project-name'
        end
      end

      it "should configure google_auth" do
        expect(AssetSync.config.google_auth).to eq("access-token")
      end

      it "should return the correct fog_options" do
        expected_fog_options = { google_auth: "access-token",
                                google_project: 'a-google-project-name',
                                provider: "Google"}
        expect(AssetSync.config.fog_options).to eq(expected_fog_options)
      end

      it "should not require that other parameters be set" do
        expect(AssetSync.config.valid?).to eq(true)
      end
    end

    describe "when using S3 interop API" do
      before(:each) do
        AssetSync.configure do |config|
          config.google_storage_access_key_id = 'aaaa'
          config.google_storage_secret_access_key = 'bbbb'
        end
      end

      it "should configure google_storage_access_key_id" do
        expect(AssetSync.config.google_storage_access_key_id).to eq("aaaa")
      end

      it "should configure google_storage_secret_access_key" do
        expect(AssetSync.config.google_storage_secret_access_key).to eq("bbbb")
      end

      it "should return the correct fog_options" do
        expected_fog_options = { google_storage_access_key_id: "aaaa",
                                google_storage_secret_access_key: "bbbb",
                                provider: "Google"}
        expect(AssetSync.config.fog_options).to eq(expected_fog_options)
      end

      it "should not require that google_json_key_location be set" do
        expect(AssetSync.config.valid?).to eq(true)
      end

      it "should require that google_storage_secret_access_key or access_key_id be set" do

        AssetSync.configure do |config|
          config.google_storage_access_key_id = nil
          config.google_storage_secret_access_key = nil
        end

        expect(AssetSync.config.valid?).to eq(false)
      end
    end

    describe "when using service account" do
      before(:each) do
        AssetSync.configure do |config|
          config.google_json_key_location = '/path/to.json'
          config.google_project = 'a-google-project-name'
        end
      end

      it "should configure google_json_key_location" do
        expect(AssetSync.config.google_json_key_location).to eq("/path/to.json")
      end

      it "should return the correct fog_options" do
        expected_fog_options = { google_json_key_location: "/path/to.json",
                                 google_project: 'a-google-project-name',
                                provider: "Google"}
        expect(AssetSync.config.fog_options).to eq(expected_fog_options)
      end
      it "should not require that google_storage_secret_access_key or access_key_id be set" do
        expect(AssetSync.config.valid?).to eq(true)
      end
    end

    describe "when using service account with JSON key string" do
      before(:each) do
        AssetSync.configure do |config|
          config.google_json_key_string = 'a-google-json-key-string'
          config.google_project = 'a-google-project-name'
        end
      end

      it "should configure google_json_key_string" do
        expect(AssetSync.config.google_json_key_string).to eq("a-google-json-key-string")
      end

      it "should return the correct fog_options" do
        expected_fog_options = { google_json_key_string: "a-google-json-key-string",
                                 google_project: 'a-google-project-name',
                                provider: "Google"}
        expect(AssetSync.config.fog_options).to eq(expected_fog_options)
      end
      it "should not require that google_storage_secret_access_key or access_key_id be set" do
        expect(AssetSync.config.valid?).to eq(true)
      end
    end
  end

  describe 'from yml' do
    describe 'when using S3 interop API' do
      before(:each) do
        set_rails_root('google_with_yml')
        AssetSync.config = AssetSync::Config.new
      end

      it "should configure google_storage_access_key_id" do
        expect(AssetSync.config.google_storage_access_key_id).to eq("xxxx")
      end

      it "should configure google_storage_secret_access_key" do
        expect(AssetSync.config.google_storage_secret_access_key).to eq("zzzz")
      end

      it "should not configure google_json_key_location" do
        expect(AssetSync.config.google_json_key_location).to eq(nil)
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

    describe 'when using service account API' do
      before(:each) do
        set_rails_root('google_with_service_account_yml')
        AssetSync.config = AssetSync::Config.new
      end

      it "should configure google_json_key_location" do
        expect(AssetSync.config.google_json_key_location).to eq("gcs.json")
      end

      it "should not configure google_storage_secret_access_key" do
        expect(AssetSync.config.google_storage_secret_access_key).to eq(nil)
      end
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
