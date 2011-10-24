AssetSync.configure do |config|
  config.aws_access_key = ENV['AWS_ACCESS_KEY']
  config.aws_access_secret = ENV['AWS_ACCESS_SECRET']
  config.aws_bucket = ENV['AWS_BUCKET']
  # config.aws_region = "eu-west-1"
  config.existing_remote_files = "keep"
end
