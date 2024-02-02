require 'mime/types'

module AssetSync
  class MultiMime

    def self.lookup(ext)
      puts "INVOKING: #{self.class.name} => def self.lookup(ext)"
      overrides =
        ::AssetSync.config.file_ext_to_mime_type_overrides
      if overrides.key?(ext)
        return overrides.fetch(ext)
      end

      if defined?(::MIME::Types)
        ::MIME::Types.type_for(ext).first.to_s
      elsif defined?(::Mime::Type)
        ::Mime::Type.lookup_by_extension(ext).to_s
      elsif defined?(::Rack::Mime)
        ext_with_dot = ".#{ext}"
        ::Rack::Mime.mime_type(ext_with_dot)
      else
        raise "No library found for mime type lookup"
      end

    end

  end
end
