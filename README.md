# Asset Sync

Synchronises Assets between Rails and S3.

After you run assets:precompile your assets will be synchronised with your S3 
bucket, deleting unused files and only uploading the files it needs to.

## Usage

Add the gem to your Gemfile

    gem "asset_sync"

Configure __config/environments/production.rb__ to use Amazon
S3 as the asset host and ensure precompiling is enabled.

    config.action_controller.asset_host = Proc.new do |source|
      request.ssl? 'https://my_bucket.s3.amazonaws.com' : 'http://my_bucket.s3.amazonaws.com'
    end

Add your Amazon S3 configuration details to
    config/asset_sync.yml
    
    development:
      access_key_id: 'MY_ACCESS_KEY'
      secret_access_key: 'MY_ACCESS_SECRET'
      bucket: "my_bucket"

    production:
      access_key_id: 'MY_ACCESS_KEY'
      secret_access_key: 'MY_ACCESS_SECRET'
      bucket: "my_bucket"

Create a rake task e.g. __lib/tasks/assets.rake__ to attach to the rails 
precompile task:

    Rake::Task["assets:precompile"].enhance do
      AssetSync::Assets.sync
    end