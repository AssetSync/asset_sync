
[![Gem Version](https://img.shields.io/gem/v/asset_sync.svg?style=flat-square)](http://badge.fury.io/rb/asset_sync)
[![Build Status](https://img.shields.io/travis/rumblelabs/asset_sync.svg?style=flat-square)](http://travis-ci.org/rumblelabs/asset_sync)
[![Code Climate](https://img.shields.io/codeclimate/github/AssetSync/asset_sync/badges/gpa.svg?style=flat-square)](https://codeclimate.com/github/AssetSync/asset_sync)

(Build Status is broken as expected until Travis is fixed by AssetSync organization owner)


# Asset Sync

Synchronises Assets between Rails and S3.

Asset Sync is built to run with the new Rails Asset Pipeline feature introduced in **Rails 3.1**.  After you run __bundle exec rake assets:precompile__ your assets will be synchronised to your S3
bucket, optionally deleting unused files and only uploading the files it needs to.

This was initially built and is intended to work on [Heroku](http://heroku.com) but can work on any platform.

## Upgrading?

Upgraded from 1.x? Read `UPGRADING.md`

## Installation

Since 2.x, Asset Sync depends on gem `fog-core` instead of `fog`.  
This is due to `fog` is including many unused storage provider gems as its dependencies.  

Asset Sync has no idea about what provider will be used,  
so you are responsible for bundling the right gem for the provider to be used.  

In your Gemfile:
```ruby
gem "asset_sync"
gem "fog-aws"
```

### Extended Installation (Faster sync with turbosprockets)

It's possible to improve **asset:precompile** time if you are using Rails 3.2.x
the main source of which being compilation of **non-digest** assets.

[turbo-sprockets-rails3](https://github.com/ndbroadbent/turbo-sprockets-rails3)
solves this by only compiling **digest** assets. Thus cutting compile time in half.

> NOTE: It will be **deprecated in Rails 4** as sprockets-rails has been extracted
out of Rails and will only compile **digest** assets by default.

## Configuration

### Rails

Configure __config/environments/production.rb__ to use Amazon
S3 as the asset host and ensure precompiling is enabled.


``` ruby
  #config/environments/production.rb
  config.action_controller.asset_host = "//#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com"
```

Or, to use Google Storage Cloud, configure as this.

``` ruby
  #config/environments/production.rb
  config.action_controller.asset_host = "//#{ENV['FOG_DIRECTORY']}.storage.googleapis.com"
```



On **HTTPS**: the exclusion of any protocol in the asset host declaration above will allow browsers to choose the transport mechanism on the fly. So if your application is available under both HTTP and HTTPS the assets will be served to match.

> The only caveat with this is that your S3 bucket name **must not contain any periods** so, mydomain.com.s3.amazonaws.com for example would not work under HTTPS as SSL certificates from Amazon would interpret our bucket name as **not** a subdomain of s3.amazonaws.com, but a multi level subdomain. To avoid this don't use a period in your subdomain or switch to the other style of S3 URL.

``` ruby
  config.action_controller.asset_host = "//s3.amazonaws.com/#{ENV['FOG_DIRECTORY']}"
```
Or

``` ruby
  config.action_controller.asset_host = "//storage.googleapis.com/#{ENV['FOG_DIRECTORY']}"
```
On **non default S3 bucket region**: If your bucket is set to a region that is not the default US Standard (us-east-1) you must use the first style of url ``//#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com`` or amazon will return a 301 permanently moved when assets are requested. Note the caveat above about bucket names and periods.

If you wish to have your assets sync to a sub-folder of your bucket instead of into the root add the following to your ``production.rb`` file

```ruby
  # store assets in a 'folder' instead of bucket root
  config.assets.prefix = "/production/assets"
````

Also, ensure the following are defined (in production.rb or application.rb)

* **config.assets.digest** is set to **true**.
* **config.assets.enabled** is set to **true**.

Additionally, if you depend on any configuration that is setup in your `initializers` you will need to ensure that

* **config.assets.initialize\_on\_precompile** is set to **true**

### AssetSync

**AssetSync** supports the following methods of configuration.

* [Built-in Initializer](https://github.com/rumblelabs/asset_sync/blob/master/lib/asset_sync/engine.rb) (configured through environment variables)
* Rails Initializer
* A YAML config file


Using the **Built-in Initializer** is the default method and is supposed to be used with **environment** variables. It's the recommended approach for deployments on Heroku.

If you need more control over configuration you will want to use a **custom rails initializer**.

Configuration using a **YAML** file (a common strategy for Capistrano deployments) is also supported.

The recommend way to configure **asset_sync** is by using **environment variables** however it's up to you, it will work fine if you hard code them too. The main reason why using environment variables is recommended is so your access keys are not checked into version control.


### Built-in Initializer (Environment Variables)

The Built-in Initializer will configure **AssetSync** based on the contents of your environment variables.

Add your configuration details to **heroku**

``` bash
heroku config:add AWS_ACCESS_KEY_ID=xxxx
heroku config:add AWS_SECRET_ACCESS_KEY=xxxx
heroku config:add FOG_DIRECTORY=xxxx
heroku config:add FOG_PROVIDER=AWS
# and optionally:
heroku config:add FOG_REGION=eu-west-1
heroku config:add ASSET_SYNC_GZIP_COMPRESSION=true
heroku config:add ASSET_SYNC_MANIFEST=true
heroku config:add ASSET_SYNC_EXISTING_REMOTE_FILES=keep
```

Or add to a traditional unix system

``` bash
export AWS_ACCESS_KEY_ID=xxxx
export AWS_SECRET_ACCESS_KEY=xxxx
export FOG_DIRECTORY=xxxx
```

Rackspace configuration is also supported

``` bash
heroku config:add RACKSPACE_USERNAME=xxxx
heroku config:add RACKSPACE_API_KEY=xxxx
heroku config:add FOG_DIRECTORY=xxxx
heroku config:add FOG_PROVIDER=Rackspace
```

Google Storage Cloud configuration is supported as well
``` bash
heroku config:add FOG_PROVIDER=Google
heroku config:add GOOGLE_STORAGE_ACCESS_KEY_ID=xxxx
heroku config:add GOOGLE_STORAGE_SECRET_ACCESS_KEY=xxxx
heroku config:add FOG_DIRECTORY=xxxx
```

The Built-in Initializer also sets the AssetSync default for **existing_remote_files** to **keep**.

### Custom Rails Initializer (config/initializers/asset_sync.rb)

If you want to enable some of the advanced configuration options you will want to create your own initializer.

Run the included Rake task to generate a starting point.

    rails g asset_sync:install --provider=Rackspace
    rails g asset_sync:install --provider=AWS

The generator will create a Rails initializer at `config/initializers/asset_sync.rb`.

``` ruby
AssetSync.configure do |config|
  config.fog_provider = 'AWS'
  config.fog_directory = ENV['FOG_DIRECTORY']
  config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

  # Don't delete files from the store
  # config.existing_remote_files = 'keep'
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
  #
  # Log silently. Default is `true`. But you can set it to false if more logging message are preferred.
  # Logging messages are sent to `STDOUT` when `log_silently` is falsy
  # config.log_silently = true
  #
  # Allow custom assets to be cacheable. Note: The base filename will be matched
  # If you have an asset with name `app.0b1a4cd3.js`, only `app.0b1a4cd3` will need to be matched
  # only one of `cache_asset_regexp` or `cache_asset_regexps` is allowed.
  # config.cache_asset_regexp = /\.[a-f0-9]{8}$/i
  # config.cache_asset_regexps = [ /\.[a-f0-9]{8}$/i, /\.[a-f0-9]{20}$/i ]
end
```

### YAML (config/asset_sync.yml)

Run the included Rake task to generate a starting point.

    rails g asset_sync:install --use-yml --provider=Rackspace
    rails g asset_sync:install --use-yml --provider=AWS

The generator will create a YAML file at `config/asset_sync.yml`.

``` yaml
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
  # To ignore existing remote files and overwrite.
  # existing_remote_files: ignore
  # Automatically replace files with their equivalent gzip compressed version
  # gzip_compression: true
  # Fail silently.  Useful for environments such as Heroku
  # fail_silently: true
  # Always upload. Useful if you want to overwrite specific remote assets regardless of their existence
  #  eg: Static files in public often reference non-fingerprinted application.css
  #  note: You will still need to expire them from the CDN's edge cache locations
  # always_upload: ['application.js', 'application.css', !ruby/regexp '/application-/\d{32}\.css/']
  # Ignored files. Useful if there are some files that are created dynamically on the server and you don't want to upload on deploy.
  # ignored_files: ['ignore_me.js', !ruby/regexp '/ignore_some/\d{32}\.css/']
  # Allow custom assets to be cacheable. Note: The base filename will be matched
  # If you have an asset with name "app.0b1a4cd3.js", only "app.0b1a4cd3" will need to be matched
  # cache_asset_regexps: ['cache_me.js', !ruby/regexp '/cache_some\.\d{8}\.css/']

development:
  <<: *defaults

test:
  <<: *defaults

production:
  <<: *defaults
```

### Available Configuration Options

All AssetSync configuration can be modified directly using environment variables with the **Built-in initializer**. e.g.

```ruby
AssetSync.config.fog_provider == ENV['FOG_PROVIDER']
```

Simply **upcase** the ruby attribute names to get the equivalent environment variable to set. The only exception to that rule are the internal **AssetSync** config variables, they must be prepended with `ASSET_SYNC_*` e.g.

```ruby
AssetSync.config.gzip_compression == ENV['ASSET_SYNC_GZIP_COMPRESSION']
```

#### AssetSync (optional)

* **existing_remote_files**: (`'keep', 'delete', 'ignore'`) what to do with previously precompiled files. **default:** `'keep'`
* **gzip\_compression**: (`true, false`) when enabled, will automatically replace files that have a gzip compressed equivalent with the compressed version. **default:** `'false'`
* **manifest**: (`true, false`) when enabled, will use the `manifest.yml` generated by Rails to get the list of local files to upload. **experimental**. **default:** `'false'`
* **include_webpacker_assets**: (`true, false`) when enabled, will use the `manifest.json` generated by Rails/webpacker to append the webpacker assets to list of local files to upload. **experimental**. **default:** `'false'`
* **enabled**: (`true, false`) when false, will disable asset sync. **default:** `'true'` (enabled)
* **ignored\_files**: an array of files to ignore e.g. `['ignore_me.js', %r(ignore_some/\d{32}\.css)]` Useful if there are some files that are created dynamically on the server and you don't want to upload on deploy **default**: `[]`
* **cache\_asset\_regexps**: an array of files to add cache headers e.g. `['cache_me.js', %r(cache_some\.\d{8}\.css)]` Useful if there are some files that are added to sprockets assets list and need to be set as 'Cacheable' on uploaded server.  Only rails compiled regexp is matched internally **default**: `[]`


#### Fog (Required)
* **fog\_provider**: your storage provider *AWS* (S3) or *Rackspace* (Cloud Files) or *Google* (Google Storage)
* **fog\_directory**: your bucket name

#### Fog (Optional)

* **fog\_region**: the region your storage bucket is in e.g. *eu-west-1* (AWS),  *ord* (Rackspace)
* **fog\_path\_style**: To use buckets with dot in names, check https://github.com/fog/fog/issues/2381#issuecomment-28088524

#### AWS

* **aws\_access\_key\_id**: your Amazon S3 access key
* **aws\_secret\_access\_key**: your Amazon S3 access secret

#### Rackspace

* **rackspace\_username**: your Rackspace username
* **rackspace\_api\_key**: your Rackspace API Key.

#### Google Storage
* **google\_storage\_access\_key\_id**: your Google Storage access key
* **google\_storage\_secret\_access\_key**: your Google Storage access secret

#### Rackspace (Optional)

* **rackspace\_auth\_url**: Rackspace auth URL, for Rackspace London use: `https://lon.identity.api.rackspacecloud.com/v2.0`

## Amazon S3 Multiple Region Support

If you are using anything other than the US buckets with S3 then you'll want to set the **region**. For example with an EU bucket you could set the following environment variable.

``` bash
heroku config:add FOG_REGION=eu-west-1
```

Or via a custom initializer

``` ruby
AssetSync.configure do |config|
  # ...
  config.fog_region = 'eu-west-1'
end
```

Or via YAML

``` yaml
production:
  # ...
  fog_region: 'eu-west-1'
```

### Amazon (AWS) IAM Users

Amazon has switched to the more secure IAM User security policy model. When generating a user & policy for asset_sync you will need to ensure the policy has the following permissions.
You __must__ give the user permission to **s3:ListAllMyBuckets** as well as give permission to both the bucket, as well as the bucket's contents (/*). If not given all these permissions you'll see the error ```Expected(200) <=> Actual(403 Forbidden) ```

IAM User Policy Example (replace "bucket_name" with your bucket):
``` json
{
  "Statement": [
    {
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Action": "s3:PutObject*",
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::bucket_name/*"
    }
  ]
}
```

If you want to use IAM roles you must set ```config.aws_iam_roles = true``` in your initializers.
```
AssetSync.configure do |config|
  # ...
  config.aws_iam_roles = true
end
```


## Automatic gzip compression

With the `gzip_compression` option enabled, when uploading your assets. If a file has a gzip compressed equivalent we will replace that asset with the compressed version and sets the correct headers for S3 to serve it. For example, if you have a file **master.css** and it was compressed to **master.css.gz** we will upload the **.gz** file to S3 in place of the uncompressed file.

If the compressed file is actually larger than the uncompressed file we will ignore this rule and upload the standard uncompressed version.

## Fail Silently

With the `fail_silently` option enabled, when running `rake assets:precompile` AssetSync will never throw an error due to missing configuration variables.

With the new **user_env_compile** feature of Heroku (see above), this is no longer required or recommended. Yet was added for the following reasons:

> With Rails 3.1 on the Heroku cedar stack, the deployment process automatically runs `rake assets:precompile`. If you are using **ENV** variable style configuration. Due to the methods with which Heroku compile slugs, there will be an error raised by asset\_sync as the environment is not available. This causes heroku to install the `rails31_enable_runtime_asset_compilation` plugin which is not necessary when using **asset_sync** and also massively slows down the first incoming requests to your app.

> To prevent this part of the deploy from failing (asset_sync raising a config error), but carry on as normal set `fail_silently` to true in your configuration and ensure to run `heroku run rake assets:precompile` after deploy.

## Rake Task

A rake task is included within the **asset_sync** gem to perform the sync:

``` ruby
  namespace :assets do
    desc "Synchronize assets to S3"
    task :sync => :environment do
      AssetSync.sync
    end
  end
```

If `AssetSync.config.run_on_precompile` is `true` (default), then assets will be uploaded to S3 automatically after the `assets:precompile` rake task is invoked:

``` ruby
  if Rake::Task.task_defined?("assets:precompile:nondigest")
    Rake::Task["assets:precompile:nondigest"].enhance do
      Rake::Task["assets:sync"].invoke if defined?(AssetSync) && AssetSync.config.run_on_precompile
    end
  else
    Rake::Task["assets:precompile"].enhance do
      Rake::Task["assets:sync"].invoke if defined?(AssetSync) && AssetSync.config.run_on_precompile
    end
  end
```

You can disable this behavior by setting `AssetSync.config.run_on_precompile = false`.

## Sinatra/Rack Support

You can use the gem with any Rack application, but you must specify two
additional options; `prefix` and `public_path`.

```ruby
AssetSync.configure do |config|
  config.fog_provider = 'AWS'
  config.fog_directory = ENV['FOG_DIRECTORY']
  config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  config.prefix = 'assets'
  config.public_path = Pathname('./public')
end
```

Then manually call `AssetSync.sync` at the end of your asset precompilation
task.

```ruby
namespace :assets do
  desc 'Precompile assets'
  task :precompile do
    target = Pathname('./public/assets')
    manifest = Sprockets::Manifest.new(sprockets, './public/assets/manifest.json')

    sprockets.each_logical_path do |logical_path|
      if (!File.extname(logical_path).in?(['.js', '.css']) || logical_path =~ /application\.(css|js)$/) && asset = sprockets.find_asset(logical_path)
        filename = target.join(logical_path)
        FileUtils.mkpath(filename.dirname)
        puts "Write asset: #{filename}"
        asset.write_to(filename)
        manifest.compile(logical_path)
      end
    end

    AssetSync.sync
  end
end
```

## Running the specs

Make sure you have a .env file with these details:-

    AWS_ACCESS_KEY_ID=<yourkeyid>
    AWS_SECRET_ACCESS_KEY=<yoursecretkey>
    FOG_DIRECTORY=<yourbucket>

Make sure the bucket has read/write permissions.  Then to run the tests:-

    foreman run rake

## Todo

1. Add some before and after filters for deleting and uploading
2. Support more cloud storage providers
3. Better test coverage
4. Add rake tasks to clean old assets from a bucket

## Credits

Inspired by:

 - [https://github.com/moocode/asset_id](https://github.com/moocode/asset_id)
 - [https://gist.github.com/1053855](https://gist.github.com/1053855)

## License

MIT License. Copyright 2011-2013 Rumble Labs Ltd. [rumblelabs.com](http://rumblelabs.com)
