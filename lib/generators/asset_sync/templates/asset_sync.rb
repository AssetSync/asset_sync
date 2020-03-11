if defined?(AssetSync)
  AssetSync.configure do |config|
    <%- if aws? -%>
    config.fog_provider = 'AWS'
    config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
    config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    # To use AWS reduced redundancy storage.
    # config.aws_reduced_redundancy = true
    #
    # Change AWS signature version. Default is 4
    # config.aws_signature_version = 4
    #
    # Change host option in fog (only if you need to)
    # config.fog_host = "s3.amazonaws.com"
    #
    # Change port option in fog (only if you need to)
    # config.fog_port = "9000"
    #
    # Use http instead of https. Default should be "https" (at least for fog-aws)
    # config.fog_scheme = "http"
    <%- elsif google? -%>
    config.fog_provider = 'Google'
    config.google_storage_access_key_id = ENV['GOOGLE_STORAGE_ACCESS_KEY_ID']
    config.google_storage_secret_access_key = ENV['GOOGLE_STORAGE_SECRET_ACCESS_KEY']
    <%- elsif rackspace? -%>
    config.fog_provider = 'Rackspace'
    config.rackspace_username = ENV['RACKSPACE_USERNAME']
    config.rackspace_api_key = ENV['RACKSPACE_API_KEY']

    # if you need to change rackspace_auth_url (e.g. if you need to use Rackspace London)
    # config.rackspace_auth_url = "lon.auth.api.rackspacecloud.com"
    <%- elsif azure_rm? -%>
    config.fog_provider = 'AzureRM'
    config.azure_storage_account_name = ENV['AZURE_STORAGE_ACCOUNT_NAME']
    config.azure_storage_access_key = ENV['AZURE_STORAGE_ACCESS_KEY']

    # config.fog_directory specifies container name of Azure Blob storage
    <%- end -%>
    config.fog_directory = ENV['FOG_DIRECTORY']

    # Invalidate a file on a cdn after uploading files
    # config.cdn_distribution_id = "12345"
    # config.invalidate = ['file1.js']

    # Increase upload performance by configuring your region
    # config.fog_region = 'eu-west-1'
    #
    # Set `public` option when uploading file depending on value,
    # Setting to "default" makes asset sync skip setting the option
    # Possible values: true, false, "default" (default: true)
    # config.fog_public = true
    #
    # Don't delete files from the store
    # config.existing_remote_files = "keep"
    #
    # Automatically replace files with their equivalent gzip compressed version
    # config.gzip_compression = true
    #
    # Use the Rails generated 'manifest.yml' file to produce the list of files to
    # upload instead of searching the assets directory.
    # config.manifest = true
    #
    # Upload the manifest file also.
    # config.include_manifest = false
    #
    # Upload files concurrently
    # config.concurrent_uploads = false
    #
    # Path to cache file to skip scanning remote
    # config.remote_file_list_cache_file_path = './.asset_sync_remote_file_list_cache.json'
    #
    # Fail silently.  Useful for environments such as Heroku
    # config.fail_silently = true
    #
    # Log silently. Default is `true`. But you can set it to false if more logging message are preferred.
    # Logging messages are sent to `STDOUT` when `log_silently` is falsy
    # config.log_silently = true
    #
    # Allow custom assets to be cacheable. Note: The base filename will be matched
    # If you have an asset with name `app.0ba4d3.js`, only `app.0ba4d3` will need to be matched
    # config.cache_asset_regexps = [ /\.[a-f0-9]{8}$/i, /\.[a-f0-9]{20}$/i ]
    # config.cache_asset_regexp = /\.[a-f0-9]{8}$/i
  end
end
