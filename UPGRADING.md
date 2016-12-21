# Guide to upgrading from AssetSync 1.x to 2.x

Make sure that you're running the latest AssetSync 1.x release.

This upgrading guide touches on:
- Changed dependencies


## Changed dependencies
Asset Sync now depends on gem `fog-core` instead of `fog`.  
This is due to `fog` is including many unused storage provider gems as its dependencies.  

Asset Sync has no idea about what provider will be used,  
so you are responsible for bundling the right gem for the provider to be used.  

For example, when using AWS as fog provider:
```ruby
# Gemfile
gem "asset_sync"
gem "fog-aws"
```

If you don't install the required gem,  
Fog will complain (by exception) about it when provider is set by Asset Sync.  

