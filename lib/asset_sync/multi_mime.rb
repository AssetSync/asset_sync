module AssetSync
  class MultiMime

    def self.lookup(ext)

      #if defined?(Rack::Mime)
      #  ext_with_dot = ".#{ext}"
      #  Rack::Mime.mime_type(ext_with_dot)
      #else
      "#{MIME::Types.type_for(ext).first}"
      #end

    end

  end
end