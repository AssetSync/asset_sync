# Asset Sync

Synchronises Assets between Rails and S3.

Asset Sync is built to run with the new Rails Asset Pipeline feature of Rails 3.1.  After you run __bundle exec rake assets:precompile:primary RAILS_ENV=production RAILS_GROUPS=assets__ (optionally set `RAILS_GROUPS` if you're using assets group in you Gemfile) only your digest assets will be synchronised to your S3 bucket, optionally deleting unused files and only uploading the files it needs to.

This was initially built and is intended to work on [Engine Yard](http://engineyard.com)

## Installation

Add the gem to your Gemfile

    gem "asset_sync"

> The following steps are now optional as of version **0.1.7** there is a built-in initializer [lib/engine.rb](https://github.com/rumblelabs/asset_sync/blob/master/lib/asset_sync/engine.rb)

Generate the rake task and config files

    rails g asset_sync:install
    
If you would like to use a YAML file for configuration instead of the default (Rails Initializer) then 

    rails g asset_sync:install --use-yml

## Configuration

Configure __config/environments/production.rb__ to use Amazon
S3 as the asset host and ensure precompiling is enabled.

    # config/environments/production.rb
    config.action_controller.asset_host = Proc.new do |source, request|
      request.ssl? ? "https://#{ENV['AWS_BUCKET']}.s3.amazonaws.com" : "http://#{ENV['AWS_BUCKET']}.s3.amazonaws.com"
    end

We support two methods of configuration.

* Rails Initializer
* A YAML config file

Using an **Initializer** is the default method and is best used with **environment** variables. It's the recommended approach for deployments on Heroku or Engine Yard.

Using a **YAML** config file is a traditional strategy for Capistrano deployments. If you are using [Moonshine](https://github.com/railsmachine/moonshine) (which we would recommend) then it is best used with [shared configuration files](https://github.com/railsmachine/moonshine/wiki/Shared-Configuration-Files).

The recommend way to configure **asset_sync** is by using environment variables however it's up to you, it will work fine if you hard code them too. The main reason is that then your access keys are not checked into version control.

### Initializer (config/initializers/asset_sync.rb)

The generator will create a Rails initializer at `config/initializers/asset_sync.rb`.

    AssetSync.configure do |config|
      config.aws_access_key = ENV['AWS_ACCESS_KEY']
      config.aws_access_secret = ENV['AWS_ACCESS_SECRET']
      config.aws_bucket = ENV['AWS_BUCKET']
      # config.aws_region = 'eu-west-1'
      config.existing_remote_files = "keep"
    end


### YAML (config/asset_sync.yml)

If you used the `--use-yml` flag, the generator will create a YAML file at `config/initializers/asset_sync.rb`.

    defaults: &defaults
      aws_access_key: "<%= ENV['AWS_ACCESS_KEY'] %>"
      aws_access_secret: "<%= ENV['AWS_ACCESS_SECRET'] %>"
      # You may need to specify what region your S3 bucket is in
      # aws_region: "eu-west-1"

    development:
      <<: *defaults
      aws_bucket: "rails-app-development"
      existing_remote_files: keep # Existing pre-compiled assets on S3 will be kept

    test:
      <<: *defaults
      aws_bucket: "rails-app-test"
      existing_remote_files: keep

    production:
      <<: *defaults
      aws_bucket: "rails-app-production"
      existing_remote_files: delete # Existing pre-compiled assets on S3 will be deleted

### Environment Variables

Add your Amazon S3 configuration details to **heroku**

    heroku config:add AWS_ACCESS_KEY=xxxx
    heroku config:add AWS_ACCESS_SECRET=xxxx
    heroku config:add AWS_BUCKET=xxxx

Or add to a traditional unix system

    export AWS_ACCESS_KEY=xxxx
    export AWS_ACCESS_SECRET=xxxx
    export AWS_BUCKET=xxxx

### Available Configuration Options

* **aws\_access\_key**: your Amazon S3 access key
* **aws\_access\_secret**: your Amazon S3 access secret
* **aws\_region**: the region your S3 bucket is in e.g. *eu-west-1*
* **existing_remote_files**: what to do with previously precompiled files, options are **keep** or **delete**

## Amazon S3 Multiple Region Support

If you are using anything other than the US buckets with S3 then you'll want to set the **region**. For example with an EU bucket you could set the following with YAML.

    production:
      # ...
      aws\_region: 'eu-west-1'

Or via the initializer

    AssetSync.configure do |config|
      # ...
      config.aws_region = 'eu-west-1'
    end

## Todo

1. Add some before and after filters for deleting and uploading
2. Support more cloud storage providers
3. Better test coverage

## Credits

Have borrowed ideas from:

 - [https://github.com/moocode/asset_id](https://github.com/moocode/asset_id)
 - [https://gist.github.com/1053855](https://gist.github.com/1053855)

## License

MIT License. Copyright 2011 Rumble Labs Ltd. [rumblelabs.com](http://rumblelabs.com)
