module Spree
  module Marketplace
    # Idempotent setup for an EcloudMall (South Africa) store.
    #   bin/rails ecloudmall:setup
    class Setup
      def initialize(store: Spree::Store.default, io: $stdout)
        @store = store
        @io = io
      end

      attr_reader :store

      def configure_store
        za = Spree::Country.find_by!(iso: 'ZA')

        store.update!(
          name: 'EcloudMall',
          default_currency: 'ZAR',
          supported_currencies: 'ZAR',
          default_country: za,
          customer_support_email: store.customer_support_email.presence || 'hello@ecloudmall.co.za',
          mail_from_address: store.mail_from_address.presence || 'hello@ecloudmall.co.za',
          meta_description: 'EcloudMall — the marketplace for South African small businesses. Shop local, shop proudly South African.',
          seo_title: 'EcloudMall | Shop proudly South African SMMEs'
        )

        zone = Spree::Zone.find_or_create_by!(name: 'South Africa') do |z|
          z.description = 'Republic of South Africa'
          z.kind = 'country'
        end
        zone.zone_members.find_or_create_by!(zoneable: za)

        tax_category = Spree::TaxCategory.find_or_create_by!(name: 'Default')
        tax_category.update!(is_default: true) unless tax_category.is_default?
        Spree::TaxRate.find_or_create_by!(name: 'VAT', zone: zone, tax_category: tax_category) do |rate|
          rate.amount = 0.15
          rate.included_in_price = true
          rate.show_rate_in_label = true
          rate.calculator = Spree::Calculator::DefaultTax.new
        end

        stock_location
        configure_shipping(zone)
        configure_partners(zone)

        market = store.markets.find_or_initialize_by(name: 'South Africa')
        market.assign_attributes(currency: 'ZAR', default_locale: 'en', tax_inclusive: true, default: true)
        market.countries = [za]
        market.save!
        store.markets.where.not(id: market.id).find_each { |m| m.update_columns(default: false) }

        configure_payments
        configure_online_gateways
        configure_categories
        log "✔ Store configured as EcloudMall (ZAR, VAT 15% incl., #{Spree::ShippingMethod.count} delivery options)"
      end

      def load_demo_sellers
        categories = configure_categories
        shipping_category = Spree::ShippingCategory.find_or_create_by!(name: 'Default')
        tax_category = Spree::TaxCategory.find_by(is_default: true) || Spree::TaxCategory.first

        DemoData::SELLERS.each do |data|
          attrs = data.except(:products)
          seller = store.sellers.find_or_initialize_by(name: attrs[:name])
          seller.assign_attributes(attrs.merge(email: "hello@#{attrs[:name].parameterize}.co.za", ships_nationwide: true, dispatch_days: 2))
          seller.save!
          seller.approve! if seller.can_approve?

          data[:products].each do |pd|
            product = store.products.find_or_initialize_by(name: pd[:name])
            product.assign_attributes(
              description: "<p>#{pd[:description]}</p>",
              status: 'active',
              available_on: 1.day.ago,
              shipping_category: shipping_category,
              tax_category: tax_category,
              seller: seller
            )
            product.stores = [store] if product.new_record?
            product.price = pd[:price] if product.new_record?
            product.save!

            master = product.master
            price = master.prices.find_or_initialize_by(currency: 'ZAR')
            price.amount = pd[:price]
            price.compare_at_amount = pd[:compare]
            price.save!

            stock_item = master.stock_items.find_or_create_by!(stock_location: stock_location)
            stock_item.set_count_on_hand(pd[:stock]) if stock_item.count_on_hand < pd[:stock]

            taxon = categories[pd[:taxon]]
            product.taxons << taxon if taxon && !product.taxons.include?(taxon)
          end
          log "✔ #{seller.name} (#{seller.province}) — #{seller.products.count} products"
        end
      end

      private

      def log(message)
        @io&.puts(message)
      end

      def stock_location
        @stock_location ||= begin
          za = Spree::Country.find_by!(iso: 'ZA')
          location = Spree::StockLocation.order(default: :desc).first_or_initialize
          location.update!(
            name: 'EcloudMall Fulfilment Hub', admin_name: 'JHB Hub', default: true, active: true,
            address1: '1 Fulfilment Way', city: 'Midrand', zipcode: '1685',
            country: za, state: za.states.find_by(abbr: 'GT'), propagate_all_variants: true
          )
          location
        end
      end

      def configure_shipping(zone)
        shipping_category = Spree::ShippingCategory.find_or_create_by!(name: 'Default')
        tax_category = Spree::TaxCategory.find_by(is_default: true)

        Spree::ShippingMethod.where.not(name: shipping_methods_config.map { |m| m[:name] }).find_each do |method|
          method.zones.delete(zone)
        end

        shipping_methods_config.each do |config|
          method = Spree::ShippingMethod.find_or_initialize_by(name: config[:name])
          method.display_on = 'both'
          method.zones = [zone]
          method.shipping_categories = [shipping_category]
          method.tax_category = tax_category
          method.estimated_transit_business_days_min = config[:min_days] if method.respond_to?(:estimated_transit_business_days_min=)
          method.estimated_transit_business_days_max = config[:max_days] if method.respond_to?(:estimated_transit_business_days_max=)
          method.calculator ||= config[:calculator].new
          method.calculator = config[:calculator].new unless method.calculator.is_a?(config[:calculator])
          method.calculator.preferences = config[:preferences]
          method.save!
          method.calculator.save!
        end
      end

      def shipping_methods_config
        [
          { name: 'Courier to your door (free over R750)', calculator: Spree::Calculator::Shipping::PriceSack,
            preferences: { minimal_amount: 750, normal_amount: 99, discount_amount: 0, currency: 'ZAR' }, min_days: 2, max_days: 4 },
          { name: 'Express overnight (metros)', calculator: Spree::Calculator::Shipping::FlatRate,
            preferences: { amount: 179, currency: 'ZAR' }, min_days: 1, max_days: 1 }
        ]
      end

      # Pickup-point partners. Records start as *prospects* with our PROPOSED terms (see
      # docs/partnerships/paxi-pargo-partnership.md) — update them in Admin → Partners once agreed.
      PARTNERS = [
        { code: 'PAXI', name: 'Paxi', website: 'https://www.paxi.co.za', method: 'Collect at a Paxi point',
          description: 'Parcel pickup & drop-off counters inside retail stores nationwide.' },
        { code: 'PARGO', name: 'Pargo', website: 'https://pargo.co.za', method: 'Collect at a Pargo point',
          description: 'Smart pickup-point network operating through retail partners.' }
      ].freeze

      def configure_partners(zone)
        shipping_category = Spree::ShippingCategory.find_or_create_by!(name: 'Default')
        tax_category = Spree::TaxCategory.find_by(is_default: true)

        # Older single "Paxi / Pargo" method from earlier setups
        Spree::ShippingMethod.where(name: 'Collect at a pickup point (Paxi / Pargo)').find_each { |m| m.zones.delete(zone) }

        PARTNERS.each do |config|
          partner = store.partners.find_or_initialize_by(code: config[:code])
          if partner.new_record?
            partner.assign_attributes(
              name: config[:name], website: config[:website], description: config[:description], status: 'prospect',
              carrier: true, referral: true, investor: false,
              parcel_cost: 45, volume_tiers: [{ 'min_parcels' => 1000, 'parcel_cost' => 40 }, { 'min_parcels' => 5000, 'parcel_cost' => 36 }],
              referral_commission_rate: 5, referral_gmv_share_rate: 1, referral_months: 6,
              notes: 'PROPOSED terms for negotiation — not agreed. See docs/partnerships/paxi-pargo-partnership.md'
            )
            partner.save!
          end

          method = Spree::ShippingMethod.find_or_initialize_by(name: config[:method])
          method.display_on = 'both'
          method.zones = [zone]
          method.shipping_categories = [shipping_category]
          method.tax_category = tax_category
          method.partner = partner
          method.pickup_point_provider = ENV["PARTNER_#{config[:code]}_POINTS_URL"].present? ? 'Spree::PickupPointProvider::PartnerFeed' : 'Spree::PickupPointProvider::SampleDirectory'
          method.calculator = Spree::Calculator::Shipping::FlatRate.new unless method.calculator.is_a?(Spree::Calculator::Shipping::FlatRate)
          method.calculator.preferences = { amount: 59, currency: 'ZAR' }
          method.save!
          method.calculator.save!
        end
      end

      def configure_payments
        [
          { name: 'Manual EFT / Bank transfer', legacy_name: 'Instant EFT / Bank transfer', description: 'Pay via EFT to EcloudMall. Your order ships as soon as payment reflects (usually within minutes with instant EFT).' },
          { name: 'Pay on delivery (card or cash)', description: 'Tap your card or pay cash to the courier on delivery. Available for courier deliveries.' }
        ].each_with_index do |config, idx|
          method = Spree::PaymentMethod::Check.find_by(name: config[:name]) ||
                   Spree::PaymentMethod::Check.find_by(name: config[:legacy_name]) ||
                   Spree::PaymentMethod::Check.new
          method.name = config[:name]
          method.description = config[:description]
          method.active = true
          # Funds are confirmed manually (EFT reflects / courier collects) — capture from the admin
          method.auto_capture = false
          method.display_on = 'both'
          method.position = idx + 10 if method.respond_to?(:position=)
          method.stores = [store] unless method.stores.include?(store)
          method.save!
        end

        # Remove duplicates created by earlier versions of this task
        Spree::PaymentMethod::Check.where(name: 'Manual EFT / Bank transfer').order(:id).offset(1).find_each do |dup|
          dup.payments.exists? ? dup.update!(active: false) : dup.destroy
        end
      end

      # PayFast ships with PayFast's public sandbox merchant so checkout works out of the box.
      # Ozow and Yoco stay inactive until credentials are provided (ENV or Admin → Payment methods).
      def configure_online_gateways
        storefront = ENV.fetch('ECLOUDMALL_STOREFRONT_URL', 'http://localhost:3001')
        store.allowed_origins.find_or_create_by!(origin: URI.parse(storefront).then { |u| "#{u.scheme}://#{u.host}" })

        gateways = [
          { klass: Spree::Gateway::Payfast, name: 'PayFast — card, Instant EFT, SnapScan, Zapper',
            description: 'Pay securely with your card, Instant EFT, SnapScan, Zapper or Mobicred via PayFast.',
            preferences: {
              merchant_id: ENV.fetch('PAYFAST_MERCHANT_ID', '10000100'),
              merchant_key: ENV.fetch('PAYFAST_MERCHANT_KEY', '46f0cd694581a'),
              passphrase: ENV.fetch('PAYFAST_PASSPHRASE', ''),
              validate_with_server: ENV.fetch('PAYFAST_VALIDATE_ITN', 'true') == 'true',
              test_mode: ENV.fetch('PAYFAST_TEST_MODE', 'true') == 'true'
            }, active: true },
          { klass: Spree::Gateway::Ozow, name: 'Ozow — Instant EFT from your bank',
            description: 'Pay instantly from any major South African bank with Ozow. No card needed.',
            preferences: {
              site_code: ENV['OZOW_SITE_CODE'], private_key: ENV['OZOW_PRIVATE_KEY'], api_key: ENV['OZOW_API_KEY'],
              test_mode: ENV.fetch('OZOW_TEST_MODE', 'true') == 'true'
            }, active: ENV['OZOW_SITE_CODE'].present? },
          { klass: Spree::Gateway::Yoco, name: 'Yoco — card, Apple Pay, Google Pay',
            description: 'Pay by Visa, Mastercard, Amex, Apple Pay or Google Pay, secured by Yoco.',
            preferences: { secret_key: ENV['YOCO_SECRET_KEY'], webhook_secret: ENV['YOCO_WEBHOOK_SECRET'] },
            active: ENV['YOCO_SECRET_KEY'].present? }
        ]

        gateways.each_with_index do |config, idx|
          method = config[:klass].find_or_initialize_by(type: config[:klass].name)
          method.name = config[:name]
          method.description = config[:description]
          method.display_on = 'both'
          method.position = idx + 1 if method.respond_to?(:position=)
          config[:preferences].each { |key, value| method.set_preference(key, value) unless value.nil? || (value == '' && key != :passphrase) }
          method.active = config[:active] if method.new_record? || config[:active]
          method.stores = [store] unless method.stores.include?(store)
          method.save!
        end

      end

      def configure_categories
        @categories ||= begin
          taxonomy = store.taxonomies.find_or_create_by!(name: 'Categories')
          map = {}
          DemoData::CATEGORIES.each do |parent_name, children|
            parent = taxonomy.taxons.find_or_create_by!(name: parent_name, parent: taxonomy.root)
            map[parent_name] = parent
            children.each do |child|
              map[child] = taxonomy.taxons.find_or_create_by!(name: child, parent: parent)
            end
          end
          map
        end
      end
    end
  end
end
