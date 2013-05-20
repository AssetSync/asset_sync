require 'mime/types'

module AssetSync
  class MultiMime

    def self.lookup(ext)
      "#{MIME::Types.type_for(ext).first}"
      #if defined?(Rack::Mime)
      #  ext_with_dot = ".#{ext}"
      #  Rack::Mime.mime_type(ext_with_dot)
      #else
      #
      #end
    end

  end
end