# Asset Sync

Synchronises Assets between Rails and S3.

Asset Sync is built to run with the new Rails Asset Pipeline feature of Rails 3.1.  After you run __bundle exec rake assets:precompile__ your assets will be synchronised to your S3 
bucket, optionally deleting unused files and only uploading the files it needs to.

This was initially built and is intended to work on [Heroku](http://heroku.com)

## Upgrading?

If you are upgrading from a version of asset_sync **< 0.2.0** (i.e. 0.1.x). All of the references to config variables have changed to reference those used in **Fog**. Ensure to backup your `asset\_sync.rb` or `asset\_sync.yml` files and re-run the generator. You may also then need to update your ENV configuration variables (or you can change the ones that are referenced).

## KNOWN ISSUES (IMPORTANT)

We are currently trying to talk with Heroku to iron these out.

1. Will not work on heroku on an application with a *RAILS_ENV* configured as anything other than production
2. Will not work on heroku using ENV variables with the configuration as described below, you must hardcode all variables

### 1. RAILS_ENV

When you see `rake assets:precompile` during deployment. Heroku is actually running something like

    env RAILS_ENV=production DATABASE_URL=scheme://user:pass@127.0.0.1/dbname bundle exec rake assets:precompile 2>&1

This means the *RAILS_ENV* you have set via *heroku:config* is not used.

**Workaround:** you could have just one S3 bucket dedicated to assets and ensure to set keep the existing remote files

    AssetSync.configure do |config|
      ...
      config.fog_directory = 'app-assets'
      config.existing_remote_files = "keep"
    end

### 2. ENV varables not available

Currently when heroku runs `rake assets:precompile` during deployment. It does not load your Rails application's environment config. This means using any **ENV** variables you could normally depend on are not available. For now you can just run `heroku run rake assets:precompile` after deploy.

**Workaround:** you could just hardcode your AWS credentials in the initializer or yml

    AssetSync.configure do |config|
      config.aws_access_key_id = 'xxx'
      config.aws_secret_access_key = 'xxx'
      config.fog_directory = 'mybucket'
    end

## Installation

Add the gem to your Gemfile

    gem "asset_sync"

> The following steps are now optional as of version **0.1.7** there is a built-in initializer [lib/engine.rb](https://github.com/rumblelabs/asset_sync/blob/master/lib/asset_sync/engine.rb)

Generate the rake task and config file

    rails g asset_sync:install
    
If you would like to use a YAML file for configuration instead of the default (Rails Initializer) then 

    rails g asset_sync:install --use-yml

The default *provider* is `AWS` but you can pick which one you need.

    rails g asset_sync:install --provider=Rackspace
    rails g asset_sync:install --provider=AWS

## Configuration

Configure __config/environments/production.rb__ to use Amazon
S3 as the asset host and ensure precompiling is enabled.

    # config/environments/production.rb
    config.action_controller.asset_host = Proc.new do |source, request|
      request.ssl? ? "https://#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com" : "http://#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com"
    end

We support two methods of configuration.

* Rails Initializer
* A YAML config file

Using an **Initializer** is the default method and is best used with **environment** variables. It's the recommended approach for deployments on Heroku.

Using a **YAML** config file is a traditional strategy for Capistrano deployments. If you are using [Moonshine](https://github.com/railsmachine/moonshine) (which we would recommend) then it is best used with [shared configuration files](https://github.com/railsmachine/moonshine/wiki/Shared-Configuration-Files).

The recommend way to configure **asset_sync** is by using environment variables however it's up to you, it will work fine if you hard code them too. The main reason is that then your access keys are not checked into version control.

### Initializer (config/initializers/asset_sync.rb)

The generator will create a Rails initializer at `config/initializers/asset_sync.rb`.

    AssetSync.configure do |config|
      config.fog_provider = 'AWS'
      config.fog_directory = ENV['FOG_DIRECTORY']
      config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
      config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

      # Don't delete files from the store
      # config.existing_remote_files = "keep"
      #
      # Increase upload performance by configuring your region
      # config.fog_region = 'eu-west-1'
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


### YAML (config/asset_sync.yml)

If you used the `--use-yml` flag, the generator will create a YAML file at `config/asset_sync.yml`.

    defaults: &defaults
      fog_provider: "AWS"
      fog_directory: "rails-app-assets"
      aws_access_key_id: "<%= ENV['AWS_ACCESS_KEY_ID'] %>"
      aws_secret_access_key: "<%= ENV['AWS_SECRET_ACCESS_KEY'] %>"
      # You may need to specify what region your storage bucket is in
      # fog_region: "eu-west-1"
      existing_remote_files: keep # Existing pre-compiled assets on S3 will be kept
      # To delete existing remote files.
      # existing_remote_files: delete
      # Automatically replace files with their equivalent gzip compressed version
      # gzip_compression: true
      # Fail silently.  Useful for environments such as Heroku
      # fail_silently = true

    development:
      <<: *defaults

    test:
      <<: *defaults

    production:
      <<: *defaults

### Environment Variables

Add your Amazon S3 configuration details to **heroku**

    heroku config:add AWS_ACCESS_KEY_ID=xxxx
    heroku config:add AWS_SECRET_ACCESS_KEY=xxxx
    heroku config:add FOG_DIRECTORY=xxxx

Or add to a traditional unix system

    export AWS_ACCESS_KEY_ID=xxxx
    export AWS_SECRET_ACCESS_KEY=xxxx
    export FOG_DIRECTORY=xxxx

### Available Configuration Options

#### AssetSync

* **existing_remote_files**: what to do with previously precompiled files, options are **keep** or **delete**
* **gzip\_compression**: when enabled, will automatically replace files that have a gzip compressed equivalent with the compressed version.
* **manifest**: when enabled, will use the `manifest.yml` generated by Rails to get the list of local files to upload. **experimental**

#### Required (Fog)
* **fog\_provider**: your storage provider *AWS* (S3) or *Rackspace* (Cloud Files)
* **fog\_directory**: your bucket name

#### Optional

* **fog\_region**: the region your storage bucket is in e.g. *eu-west-1*

#### AWS

* **aws\_access\_key\_id**: your Amazon S3 access key
* **aws\_secret\_access\_key**: your Amazon S3 access secret

#### Rackspace

* **rackspace\_username**: your Rackspace username
* **rackspace\_api\_key**: your Rackspace API Key.

## Amazon S3 Multiple Region Support

If you are using anything other than the US buckets with S3 then you'll want to set the **region**. For example with an EU bucket you could set the following with YAML.

    production:
      # ...
      aws_region: 'eu-west-1'

Or via the initializer

    AssetSync.configure do |config|
      # ...
      config.fog_region = 'eu-west-1'
    end

## Automatic gzip compression

With the `gzip_compression` option enabled, when uploading your assets. If a file has a gzip compressed equivalent we will replace that asset with the compressed version and sets the correct headers for S3 to serve it. For example, if you have a file **master.css** and it was compressed to **master.css.gz** we will upload the **.gz** file to S3 in place of the uncompressed file.

If the compressed file is actually larger than the uncompressed file we will ignore this rule and upload the standard uncompressed version.

## Heroku

With Rails 3.1 on the Heroku cedar stack, the deployment process automatically runs `rake assets:precompile`. If you are using **ENV** variable style configuration. Due to the methods with which Heroku compile slugs, there will be an error raised by asset_sync as the environment is not available. This causes heroku to install the `rails31_enable_runtime_asset_compilation` plugin which is not necessary when using **asset_sync** and also massively slows down the first incoming requests to your app.

To prevent this part of the deploy from failing (asset_sync raising a config error), but carry on as normal set `fail_silently` to true in your configuration and ensure to run `heroku run rake assets:precompile` after deploy.

## Rake Task

A rake task is included in asset\_sync to enhance the rails precompile task by automatically running after it:

    # asset_sync/lib/tasks/asset_sync.rake
    Rake::Task["assets:precompile"].enhance do
      AssetSync.sync
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
