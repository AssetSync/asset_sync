require 'mime/types'

module AssetSync
  class MultiMime

    def self.lookup(ext)

      mime = nil
      library_found = false
      if defined?(::MIME::Types)
        mime = ::MIME::Types.type_for(ext).first
        library_found = true
      end
      if !mime && defined?(::Mime::Type)
        mime = ::Mime::Type.lookup_by_extension(ext)
        library_found = true
      end
      if !mime && defined?(::Rack::Mime)
        ext_with_dot = ".#{ext}"
        mime = ::Rack::Mime.mime_type(ext_with_dot)
        library_found = true
      end

      if !library_found
        raise "No library found for mime type lookup"
      end

      mime

    end

  end
end
