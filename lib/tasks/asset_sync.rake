namespace :assets do

  desc 'Synchronize assets to remote (assumes assets are already compiled)'
  task :sync => :environment do
    AssetSync.sync
  end
  namespace :sync do
    desc 'Delete out-of-sync files on remote'
    task :clean => :environment do
      AssetSync.clean
    end
  end

end

if Rake::Task.task_defined?("assets:precompile:nondigest")
  Rake::Task["assets:precompile:nondigest"].enhance do
    # Conditional execution needs to be inside the enhance block because the enhance block
    # will get executed before yaml or Rails initializers.
    Rake::Task["assets:sync"].invoke if defined?(AssetSync) && AssetSync.config.run_on_precompile
  end
else
  # Triggers on webpacker compile task instead of assets:precompile to ensure
  # that syncing is done after all assets are compiled
  # (webpacker:compile already enhances assets:precompile)
  if Rake::Task.task_defined?("webpacker:compile")
    Rake::Task['webpacker:compile'].enhance do
      if defined?(AssetSync) && AssetSync.config.run_on_precompile && AssetSync.config.include_webpacker_assets
        Rake::Task["assets:sync"].invoke
      end
    end
  end

  Rake::Task['assets:precompile'].enhance do
    # rails 3.1.1 will clear out Rails.application.config if the env vars
    # RAILS_GROUP and RAILS_ENV are not defined. We need to reload the
    # assets environment in this case.
    # Rake::Task["assets:environment"].invoke if Rake::Task.task_defined?("assets:environment")
    if defined?(AssetSync) && AssetSync.config.run_on_precompile && !AssetSync.config.include_webpacker_assets
      Rake::Task["assets:sync"].invoke
    end
  end
end
