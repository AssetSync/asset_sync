Rake::Task["assets:precompile:primary"].enhance do
  AssetSync.sync
end
