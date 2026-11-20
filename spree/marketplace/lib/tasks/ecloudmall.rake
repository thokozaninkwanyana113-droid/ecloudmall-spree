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

namespace :ecloudmall do
  namespace :ledger do
    desc 'Re-sync the seller/partner ledger with paid orders and refunds (DAYS=45). Safe to run repeatedly.'
    task sync: :environment do
      days = ENV.fetch('DAYS', 45).to_i
      Spree::Store.find_each do |store|
        Spree::Marketplace::Ledger.sync_recent!(store: store, days: days)
        puts "✔ #{store.name}: ledger synced for orders completed in the last #{days} days"
      end
    end
  end

  desc 'Close last month for every live partner (accrue parcel costs & referral share for payout)'
  task close_partner_month: :environment do
    month = Date.current.prev_month
    Spree::Partner.live.find_each do |partner|
      entries = Spree::Marketplace::Ledger.close_partner_month!(partner, month: month)
      puts "✔ #{partner.name}: #{month.strftime('%B %Y')} closed (#{entries.size} entries)"
    end
  end
end
