namespace :ecloudmall do
  desc 'Configure the default store as EcloudMall (ZAR, VAT 15%, SA delivery & payments)'
  task setup_store: :environment do
    Spree::Marketplace::Setup.new.configure_store
  end

  desc 'Load demo SMME sellers and products (one per South African province)'
  task load_demo: :environment do
    Spree::Marketplace::Setup.new.load_demo_sellers
  end

  desc 'Full setup: store configuration + demo sellers'
  task setup: %i[setup_store load_demo]
end
