Rake::Task["assets:precompile"].enhance do
  AssetSync.sync
end