# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "asset_sync/version"

Gem::Specification.new do |s|
  s.name        = "asset_sync"
  s.version     = AssetSync::VERSION
  s.date        = "2013-08-26"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Simon Hamilton", "David Rice", "Phil McClure", "Toby Osbourn"]
  s.email       = ["shamilton@rumblelabs.com", "me@davidjrice.co.uk", "pmcclure@rumblelabs.com", "tosbourn@rumblelabs.com"]
  s.homepage    = "https://github.com/rumblelabs/asset_sync"
  s.summary     = %q{Synchronises Assets in a Rails 3 application and Amazon S3/Cloudfront and Rackspace Cloudfiles}
  s.description = %q{After you run assets:precompile your compiled assets will be synchronised with your S3 bucket.}

  s.rubyforge_project = "asset_sync"

  s.add_dependency('fog', ">= 1.8.0")
  s.add_dependency('unf')
  s.add_dependency('activemodel')

  s.add_development_dependency "rspec"
  s.add_development_dependency "bundler"
  s.add_development_dependency "jeweler"

  s.add_development_dependency "uglifier"
  s.add_development_dependency "appraisal"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
