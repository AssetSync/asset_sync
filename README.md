# Asset Sync

Synchronises Assets between Rails and S3.

Asset Sync is built to run with the new Rails Asset Pipeline feature of Rails 3.1.  After you run __bundle exec rake assets:precompile__ your assets will be synchronised to your S3 
bucket, optionally deleting unused files and only uploading the files it needs to.

This was initially built and is intended to work on [Heroku](http://heroku.com)

## Installation

Add the gem to your Gemfile

    gem "asset_sync"

Generate the rake task and config files

    rails g asset_sync:install

## Configuration

Configure __config/environments/production.rb__ to use Amazon
S3 as the asset host and ensure precompiling is enabled.

    # config/environments/production.rb
    config.action_controller.asset_host = Proc.new do |source|
      request.ssl? 'https://my_bucket.s3.amazonaws.com' : 'http://my_bucket.s3.amazonaws.com'
    end

Add your Amazon S3 configuration details to **asset_sync.yml**
    
    # config/asset_sync.yml
    development:
      access_key_id: 'MY_ACCESS_KEY'
      secret_access_key: 'MY_ACCESS_SECRET'
      bucket: "my_bucket"
      existing_remote_files: "keep"

    production:
      access_key_id: 'MY_ACCESS_KEY'
      secret_access_key: 'MY_ACCESS_SECRET'
      bucket: "my_bucket"
      existing_remote_files: "delete"

If you are using anything other than the US buckets with S3 then you'll want to set the **region**. For example with an EU bucket you could set the following

    production:
      access_key_id: 'MY_ACCESS_KEY'
      secret_access_key: 'MY_ACCESS_SECRET'
      region: 'eu-west-1'

A rake task is installed with the generator to enhance the rails 
precompile task by automatically running after it:

    # lib/tasks/asset_sync.rake
    Rake::Task["assets:precompile"].enhance do
      AssetSync::Assets.sync
    end

## Todo

1. Write some specs
2. Add some before and after filters for deleting and uploading
3. Provide more configuration options

## Credits

Have borrowed ideas from:

 - [https://github.com/moocode/asset_id](https://github.com/moocode/asset_id)
 - [https://gist.github.com/1053855](https://gist.github.com/1053855)

## License

MIT License. Copyright 2011 Rumble Labs Ltd. [rumblelabs.com](http://rumblelabs.com)