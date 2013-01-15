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

    it "should default AssetSync to enabled" do
      AssetSync.config.enabled?.should be_true
      AssetSync.enabled?.should be_true
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

    it "should configure aws_secret_access_key" do
      AssetSync.config.aws_secret_access_key.should == "bbbb"
    end

    it "should configure aws_access_key" do
      AssetSync.config.fog_directory.should == "mybucket"
    end

    it "should configure fog_region" do
      AssetSync.config.fog_region.should == "eu-west-1"
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
      set_rails_root('aws_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should default AssetSync to enabled" do
      AssetSync.config.enabled?.should be_true
      AssetSync.enabled?.should be_true
    end

    it "should configure aws_access_key_id" do
      AssetSync.config.aws_access_key_id.should == "xxxx"
    end

    it "should configure aws_secret_access_key" do
      AssetSync.config.aws_secret_access_key.should == "zzzz"
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

    it "should default gzip_compression to false" do
      AssetSync.config.gzip_compression.should be_false
    end

    it "should default manifest to false" do
      AssetSync.config.manifest.should be_false
    end
  end

  describe 'from yml, exporting to a mobile hybrid development directory' do
    before(:each) do
      Rails.env.replace('hybrid')
      set_rails_root('aws_with_yml')
      AssetSync.config = AssetSync::Config.new
    end

    it "should be disabled" do
      lambda{ AssetSync.sync }.should_not raise_error(AssetSync::Config::Invalid)
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
      lambda{ AssetSync.sync }.should raise_error(AssetSync::Config::Invalid)
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
      lambda{ AssetSync.sync }.should_not raise_error(AssetSync::Config::Invalid)
    end
  end

  describe 'with fail_silent configuration' do
    before(:each) do
      AssetSync.stub(:stderr).and_return(@stderr = StringIO.new)
      AssetSync.config = AssetSync::Config.new
      AssetSync.configure do |config|
        config.fail_silently = true
      end
    end

    it "should not raise an invalid exception" do
      lambda{ AssetSync.sync }.should_not raise_error(AssetSync::Config::Invalid)
    end

    it "should output a warning to stderr" do
      AssetSync.sync
      @stderr.string.should =~ /can't be blank/
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
