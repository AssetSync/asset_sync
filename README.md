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
    config.action_controller.asset_host = Proc.new do |source, request|
      request.ssl? ? 'https://my_bucket.s3.amazonaws.com' : 'http://my_bucket.s3.amazonaws.com'
    end

### asset_sync.yml

The recommend way to configure your **asset_sync.yml** is by adding an environment variable. That way your access keys are not checked into version control.

    defaults: &defaults
      access_key_id: "<%= ENV['AWS_ACCESS_KEY'] %>"
      secret_access_key: "<%= ENV['AWS_ACCESS_SECRET'] %>"
      # You may need to specify what region your S3 bucket is in
      # region: "eu-west-1"

    development:
      <<: *defaults
      bucket: "backoffice_development"
      existing_remote_files: keep # Existing pre-compiled assets on S3 will be kept

    test:
      <<: *defaults
      bucket: "backoffice_test"
      existing_remote_files: keep

    production:
      <<: *defaults
      bucket: "backoffice_production"
      existing_remote_files: delete # Existing pre-compiled assets on S3 will be deleted


Add your Amazon S3 configuration details to **heroku**

    heroku config:add AWS_ACCESS_KEY=xxxx
    heroku config:add AWS_ACCESS_KEY=xxxx

Or add to a traditional unix system

    export AWS_ACCESS_KEY=xxxx
    export AWS_ACCESS_SECRET=xxxx

If you are using anything other than the US buckets with S3 then you'll want to set the **region**. For example with an EU bucket you could set the following

    production:
      access_key_id: 'MY_ACCESS_KEY'
      secret_access_key: 'MY_ACCESS_SECRET'
      region: 'eu-west-1'

### Available Configuration Options

* **access\_key\_id**: your Amazon S3 access key
* **secret_access\_key**: your Amazon S3 access secret
* **region**: the region your S3 bucket is in e.g. *eu-west-1*
* **existing_remote_files**: what to do with previously precompiled files, options are **keep** or **delete**

## Rake Task

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

  * Get config working for new and old styles
  * Get main class stuff working again


## Credits

Have borrowed ideas from:

 - [https://github.com/moocode/asset_id](https://github.com/moocode/asset_id)
 - [https://gist.github.com/1053855](https://gist.github.com/1053855)

## License

MIT License. Copyright 2011 Rumble Labs Ltd. [rumblelabs.com](http://rumblelabs.com)