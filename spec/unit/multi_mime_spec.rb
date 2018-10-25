require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync::MultiMime do

  before(:each) do
    # Object#remove_const does not remove the loaded
    # file from the $" variable
    #
    # So we need do both
    #
    # 1. Remove constant(s) to avoid warning messages
    # 2. Remove loaded file(s)
    Object.send(:remove_const, :Rails) if defined?(Rails)
    Object.send(:remove_const, :Mime) if defined?(Mime)
    Object.send(:remove_const, :Rack) if defined?(Rack)
    Object.send(:remove_const, :MIME) if defined?(MIME)

    $".grep(/mime\//).each do |file_path|
      $".delete(file_path)
    end
  end

  after(:each) do
    # Object#remove_const does not remove the loaded
    # file from the $" variable
    #
    # So we need do both
    #
    # 1. Remove constant(s) to avoid warning messages
    # 2. Remove loaded file(s)
    Object.send(:remove_const, :Rails) if defined?(Rails)
    Object.send(:remove_const, :Mime) if defined?(Mime)
    Object.send(:remove_const, :Rack) if defined?(Rack)
    Object.send(:remove_const, :MIME) if defined?(MIME)

    $".grep(/mime\//).each do |file_path|
      $".delete(file_path)
    end

    AssetSync.config = AssetSync::Config.new
  end

  after(:all) do
    require 'mime/types'
  end

  describe 'Mime::Type' do

    it 'should detect mime type' do
      require 'rails'
      expect(AssetSync::MultiMime.lookup('css')).to eq("text/css")
    end

  end

  describe 'Rack::Mime' do

    it 'should detect mime type' do
      require 'rack/mime'
      expect(AssetSync::MultiMime.lookup('css')).to eq("text/css")
    end

  end

  describe 'MIME::Types' do

    it 'should detect mime type' do
      require 'mime/types'
      expect(AssetSync::MultiMime.lookup('css')).to eq("text/css")
    end

  end

  describe "use of option file_ext_to_mime_type_overrides" do
    before(:each) do
      require 'mime/types'
    end

    context "with default value" do
      it "should return default value set by gem" do
        expect(
          AssetSync::MultiMime.lookup("js").to_s,
        ).to eq("application/javascript")
      end
    end
    context "with empty value" do
      before(:each) do
        AssetSync.config = AssetSync::Config.new
        AssetSync.configure do |config|
          config.file_ext_to_mime_type_overrides.clear
        end
      end

      it "should return value from mime-types gem" do
        expect(
          AssetSync::MultiMime.lookup("js").to_s,
        ).to eq(::MIME::Types.type_for("js").first.to_s)
      end
    end
    context "with custom value" do
      before(:each) do
        AssetSync.config = AssetSync::Config.new
        AssetSync.configure do |config|
          config.file_ext_to_mime_type_overrides.add(
            :js,
            :"application/x-javascript",
          )
        end
      end

      it "should return custom value" do
        expect(
          AssetSync::MultiMime.lookup("js").to_s,
        ).to eq("application/x-javascript")
      end
    end
  end

end
