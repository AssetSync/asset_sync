# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "asset_sync/version"

Gem::Specification.new do |s|
  s.name        = "asset_sync"
  s.version     = AssetSync::VERSION
  s.date        = "2011-08-05"
  s.platform    = Gem::Platform::RUBY 
  s.authors     = ["Simon Hamilton", "David Rice"]
  s.email       = ["shamilton@rumblelabs.com", "me@davidjrice.co.uk"]
  s.homepage    = "https://github.com/rumblelabs/asset_sync"
  s.summary     = %q{Synchronises Assets between Rails and S3}
  s.description = %q{After you run assets:precompile your assets will be synchronised with your S3 bucket, deleting unused files and only uploading the files it needs to.}

  s.rubyforge_project = "asset_sync"

  s.add_dependency('fog')
  
  s.add_development_dependency "rspec"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
