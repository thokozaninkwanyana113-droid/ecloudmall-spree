Rails.application.config.after_initialize do
  Spree.admin.navigation.sidebar.add :sellers,
                                     label: 'marketplace.admin.sellers',
                                     url: :admin_sellers_path,
                                     icon: 'building-store',
                                     position: 35,
                                     active: -> { controller_name == 'sellers' },
                                     if: -> { can?(:manage, Spree::Seller) },
                                     badge: -> {
                                       count = current_store.sellers.pending.count
                                       count if count.positive?
                                     },
                                     badge_class: 'badge-warning'

  Spree.admin.tables.register(:sellers, model_class: Spree::Seller, search_param: :name_cont)

  Spree.admin.tables.sellers.add :name, label: :name, type: :link, sortable: true, filterable: true, default: true, position: 10
  Spree.admin.tables.sellers.add :status, label: :status, type: :custom, sortable: true, filterable: true,
                                          filter_type: :status, default: true, position: 20,
                                          partial: 'spree/admin/sellers/status_badge',
                                          partial_locals: ->(record) { { seller: record } },
                                          value_options: Spree::Seller::STATUSES.map { |s| { value: s, label: s.titleize } }
  Spree.admin.tables.sellers.add :province, label: 'marketplace.admin.province', type: :string, sortable: true, filterable: true, default: true, position: 30
  Spree.admin.tables.sellers.add :city, label: :city, type: :string, sortable: true, filterable: true, default: true, position: 40
  Spree.admin.tables.sellers.add :primary_category, label: 'marketplace.admin.category', type: :string, sortable: true, filterable: true, default: true, position: 50
  Spree.admin.tables.sellers.add :black_owned, label: 'marketplace.admin.black_owned', type: :boolean, sortable: true, filterable: true, default: false, position: 60
  Spree.admin.tables.sellers.add :women_owned, label: 'marketplace.admin.women_owned', type: :boolean, sortable: true, filterable: true, default: false, position: 70
  Spree.admin.tables.sellers.add :featured, label: 'marketplace.admin.featured', type: :boolean, sortable: true, filterable: true, default: true, position: 80
  Spree.admin.tables.sellers.add :created_at, label: 'marketplace.admin.applied_at', type: :datetime, sortable: true, filterable: true, default: true, position: 90

  Spree.admin.navigation.sidebar.add :partners,
                                     label: 'marketplace.admin.partners',
                                     url: :admin_partners_path,
                                     icon: 'truck-delivery',
                                     position: 36,
                                     active: -> { controller_name == 'partners' },
                                     if: -> { can?(:manage, Spree::Partner) }

  Spree.admin.tables.register(:partners, model_class: Spree::Partner, search_param: :name_cont)
  Spree.admin.tables.partners.add :name, label: :name, type: :link, sortable: true, filterable: true, default: true, position: 10
  Spree.admin.tables.partners.add :code, label: 'marketplace.admin.code', type: :string, sortable: true, filterable: true, default: true, position: 20
  Spree.admin.tables.partners.add :status, label: :status, type: :string, sortable: true, filterable: true, default: true, position: 30
  Spree.admin.tables.partners.add :carrier, label: 'marketplace.admin.carrier', type: :boolean, sortable: true, default: true, position: 40
  Spree.admin.tables.partners.add :referral, label: 'marketplace.admin.referral', type: :boolean, sortable: true, default: true, position: 50
  Spree.admin.tables.partners.add :investor, label: 'marketplace.admin.investor', type: :boolean, sortable: true, default: true, position: 60

  Spree.admin.navigation.sidebar.add :finance,
                                     label: 'marketplace.finance.title',
                                     url: :admin_finance_path,
                                     icon: 'cash',
                                     position: 37,
                                     active: -> { %w[finance payout_batches].include?(controller_name) },
                                     if: -> { can?(:manage, Spree::PayoutBatch) }
end
