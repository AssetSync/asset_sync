The following issues are currently present in Heroku if you are not following the steps outlined in the main [README](http://github.com/rumblelabs/asset_sync)

## KNOWN ISSUES (IMPORTANT)

We are currently trying to talk with Heroku to iron these out.

1. Will not work on heroku on an application with a *RAILS_ENV* configured as anything other than production
2. Will not work on heroku using ENV variables with the configuration as described below, you must hardcode all variables

### 1. RAILS_ENV

When you see `rake assets:precompile` during deployment. Heroku is actually running something like

    env RAILS_ENV=production DATABASE_URL=scheme://user:pass@127.0.0.1/dbname bundle exec rake assets:precompile 2>&1

This means the *RAILS_ENV* you have set via *heroku:config* is not used.

**Workaround:** you could have just one S3 bucket dedicated to assets and configure `AssetSync` to not delete existing files:

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
