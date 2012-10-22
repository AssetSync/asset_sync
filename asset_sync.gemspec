# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "asset_sync/version"

Gem::Specification.new do |s|
  s.name        = "asset_sync"
  s.version     = AssetSync::VERSION
  s.date        = "2012-10-22"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Simon Hamilton", "David Rice", "Phil McClure"]
  s.email       = ["shamilton@rumblelabs.com", "me@davidjrice.co.uk", "pmcclure@rumblelabs.com"]
  s.homepage    = "https://github.com/rumblelabs/asset_sync"
  s.summary     = %q{Synchronises Assets in a Rails 3 application and Amazon S3/Cloudfront and Rackspace Cloudfiles}
  s.description = %q{After you run assets:precompile your compiled assets will be synchronised with your S3 bucket.}

  s.rubyforge_project = "asset_sync"

  s.add_dependency('fog')
  s.add_dependency('activemodel')

  s.add_development_dependency "rspec"
  s.add_development_dependency "bundler"
  s.add_development_dependency "jeweler"

  # s.files         = `git ls-files`.split("\n")
  # s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = %w(.gitignore .travis.yml CHANGELOG.md Gemfile README.md Rakefile asset_sync.gemspec docs/heroku.md lib/asset_sync.rb lib/asset_sync/asset_sync.rb lib/asset_sync/config.rb lib/asset_sync/engine.rb lib/asset_sync/railtie.rb lib/asset_sync/storage.rb lib/asset_sync/version.rb lib/generators/asset_sync/install_generator.rb lib/generators/asset_sync/templates/asset_sync.rb lib/generators/asset_sync/templates/asset_sync.yml lib/tasks/asset_sync.rake spec/asset_sync_spec.rb spec/aws_with_yml/config/asset_sync.yml spec/google_spec.rb spec/google_with_yml/config/asset_sync.yml spec/rackspace_spec.rb spec/rackspace_with_yml/config/asset_sync.yml spec/railsless_spec.rb spec/spec_helper.rb spec/storage_spec.rb)
  s.test_files = %w(spec/asset_sync_spec.rb spec/aws_with_yml/config/asset_sync.yml spec/google_spec.rb spec/google_with_yml/config/asset_sync.yml spec/rackspace_spec.rb spec/rackspace_with_yml/config/asset_sync.yml spec/railsless_spec.rb spec/spec_helper.rb spec/storage_spec.rb)
  s.executables = []
  s.require_paths = ["lib"]
end
