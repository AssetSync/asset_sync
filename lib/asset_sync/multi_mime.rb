require 'mime/types'

module AssetSync
  class MultiMime

    def self.lookup(ext)

      if defined?(::MIME::Types)
        ::MIME::Types.type_for(ext).first
      elsif defined?(::Mime::Type)
        ::Mime::Type.lookup_by_extension(ext)
      elsif defined?(::Rack::Mime)
        ext_with_dot = ".#{ext}"
        ::Rack::Mime.mime_type(ext_with_dot)
      else
        raise "No library found for mime type lookup"
      end

    end

  end
end
