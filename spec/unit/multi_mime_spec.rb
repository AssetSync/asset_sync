require File.dirname(__FILE__) + '/../spec_helper'

describe AssetSync::MultiMime do

  describe 'Mime::Type' do

    it 'should detect mime type' do
      Object.send(:remove_const, :Rails) if defined?(Rails)
      require 'rails'
      AssetSync::MultiMime.lookup('css').should == "text/css"
    end

    after(:each) do
      Object.send(:remove_const, :Rails) if defined?(Rails)
      Object.send(:remove_const, :Mime) if defined?(Mime)
    end

  end

  describe 'Rack::Mime' do

    it 'should detect mime type' do
      require 'rack/mime'
      AssetSync::MultiMime.lookup('css').should == "text/css"
    end

    after(:each) do
      Object.send(:remove_const, :Rack) if defined?(Rack)
    end

  end

  describe 'MIME::Types' do

    it 'should detect mime type' do
      Object.send(:remove_const, :MIME) if defined?(MIME)
      require 'mime/types'
      AssetSync::MultiMime.lookup('css').should == "text/css"
    end

    after(:each) do
      Object.send(:remove_const, :MIME) if defined?(MIME)
    end

  end

end