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
