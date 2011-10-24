AssetSync.configure do |config|
  config.aws_access_key = ENV['AWS_ACCESS_KEY_ID']
  config.aws_access_secret = ENV['AWS_SECRET_ACCESS_KEY']
  config.aws_bucket = ENV['FOG_DIRECTORY']
  # config.fog_region = "eu-west-1"
  config.existing_remote_files = "keep"
end