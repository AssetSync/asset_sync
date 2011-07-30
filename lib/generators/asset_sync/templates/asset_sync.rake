Rake::Task["assets:precompile"].enhance do
  AssetSync::Assets.sync
end