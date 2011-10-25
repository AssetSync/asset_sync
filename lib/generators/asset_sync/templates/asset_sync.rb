AssetSync.configure do |config|
  <%- if aws? -%>
  config.fog_provider = 'AWS'
  config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  <%- elsif rackspace? -%>
  config.fog_provider = 'Rackspace'
  config.rackspace_username = ENV['RACKSPACE_USERNAME']
  config.rackspace_api_key = ENV['RACKSPACE_API_KEY']
  <%- end -%>
  config.fog_directory = ENV['FOG_DIRECTORY']
  # config.fog_region = "eu-west-1"
  config.existing_remote_files = "keep"
end