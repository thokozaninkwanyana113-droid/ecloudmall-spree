# encoding: UTF-8

require_relative '../core/lib/spree/core/version.rb'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_marketplace'
  s.version     = Spree.version
  s.authors     = ['EcloudMall']
  s.summary     = 'Multi-seller marketplace for South African SMMEs (EcloudMall)'
  s.description = 'Adds sellers (SMME sellers), seller onboarding applications, seller-aware product catalog, ' \
                  'South African business attributes (B-BBEE, CIPC, provinces) and commission tracking to Spree.'
  s.homepage    = 'https://github.com/thokozaninkwanyana113-droid/ecloudmall-spree'
  s.license     = 'BSD-3-Clause'

  s.required_ruby_version = '>= 3.2'

  s.files        = Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']
  s.require_path = 'lib'

  s.add_dependency 'spree_core', ">= #{s.version}"
  s.add_dependency 'spree_api', ">= #{s.version}"
  s.add_dependency 'spree_admin', ">= #{s.version}"
end
