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

namespace :ecloudmall do
  desc 'Production-safe first-run setup: store, payments and partners from ENV; never loads demo data unless ECLOUDMALL_DEMO_DATA=true'
  task bootstrap: :environment do
    if Rails.env.production?
      default_admin = Spree.admin_user_class.find_by(email: 'spree@example.com')
      if default_admin&.valid_password?('spree123')
        abort '✘ The default admin login (spree@example.com / spree123) exists. Set ADMIN_EMAIL and ADMIN_PASSWORD ' \
              'before the first deploy, or change that admin\'s password, then run bootstrap again.'
      end
    end

    setup = Spree::Marketplace::Setup.new
    setup.configure_store
    setup.load_demo_vendors if ENV['ECLOUDMALL_DEMO_DATA'] == 'true'

    store = Spree::Store.default
    key = Spree::ApiKey.where(store: store).publishable.first || Spree::ApiKey.create!(store: store, key_type: 'publishable', name: 'Storefront')
    active = store.payment_methods.active.order(:position).pluck(:name)
    puts "✔ Store URL: #{store.url.presence || '(set ECLOUDMALL_STORE_URL)'} · storefront origins: #{store.allowed_origins.pluck(:origin).join(', ')}"
    puts "✔ Active payment methods: #{active.join(' | ')}"
    puts "✔ Storefront publishable key (set SPREE_PUBLISHABLE_KEY on the storefront): #{key.token}"
  end
end

namespace :ecloudmall do
  desc 'Run ecloudmall:bootstrap only if the store has not been set up yet (used by the Docker entrypoint)'
  task bootstrap_once: :environment do
    store = Spree::Store.default
    if store&.default_currency == 'ZAR' && store.markets.exists?(name: 'South Africa') && ENV['ECLOUDMALL_FORCE_BOOTSTRAP'] != 'true'
      puts '✔ EcloudMall already bootstrapped — skipping (set ECLOUDMALL_FORCE_BOOTSTRAP=true to re-apply ENV settings)'
    else
      Rake::Task['ecloudmall:bootstrap'].invoke
    end
  end
end
