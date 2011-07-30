# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "asset_sync"
  s.version     = '0.0.1'
  s.date        = '2011-07-30'
  s.authors     = ["Simon Hamilton"]
  s.email       = ["shamilton@rumblelabs.com"]
  s.homepage    = ""
  s.summary     = "Synchronises Assets between Rails and S3"
  s.description = "After you run assets:precompile your assets will be synchronised with your S3 bucket, deleting unused files and only uploading the files it needs to."

  s.rubyforge_project = "asset_sync"

  s.add_dependency('fog')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
