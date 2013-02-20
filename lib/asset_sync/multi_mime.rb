module AssetSync
  class MultiMime

    types={
      "ttf"=> "font/truetype"
    }

    def self.lookup(ext)

      #if defined?(Rack::Mime)
      #  ext_with_dot = ".#{ext}"
      #  Rack::Mime.mime_type(ext_with_dot)
      #else
      types[ext] || "#{MIME::Types.type_for(ext).first}"
      #end

    end

  end
end