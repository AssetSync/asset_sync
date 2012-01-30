# Rails 3.2 compatibility
if Rails.application.config.assets.digest
  Rake::Task["assets:precompile:nondigest"].enhance do
    Rake::Task["assets:environment"].invoke if Rake::Task.task_defined?("assets:environment")
    AssetSync.sync
  end
# Rails 3.1.x compatibility
else
  Rake::Task["assets:precompile"].enhance do
    # rails 3.1.1 will clear out Rails.application.config if the env vars
    # RAILS_GROUP and RAILS_ENV are not defined. We need to reload the
    # assets environment in this case.
    Rake::Task["assets:environment"].invoke if Rake::Task.task_defined?("assets:environment")
    AssetSync.sync
  end
end