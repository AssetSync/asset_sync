AssetSync.configure do |config|
  <%- if aws? -%>
  config.fog_provider = 'AWS'
  config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  # To use AWS reduced redundancy storage.
  # config.aws_reduced_redundancy = true
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
  <%- end -%>
  config.fog_directory = ENV['FOG_DIRECTORY']

  # Invalidate a file on a cdn after uploading files
  # config.cdn_distribution_id = "12345"
  # config.invalidate = ['file1.js']

  # Increase upload performance by configuring your region
  # config.fog_region = 'eu-west-1'
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
  # Fail silently.  Useful for environments such as Heroku
  # config.fail_silently = true
end
