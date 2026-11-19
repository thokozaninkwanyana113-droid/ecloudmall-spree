module Spree
  # A commercial partner of the marketplace — e.g. a pickup-point network (Paxi, Pargo) acting as
  # carrier, seller-referral channel and/or investor. Terms live here so partner statements are
  # computed from real orders rather than spreadsheets.
  class Partner < Spree.base_class
    acts_as_paranoid
    include Spree::SingleStoreResource

    has_prefix_id :prt

    STATUSES = %w[prospect in_talks pilot active paused].freeze
    LIVE_STATUSES = %w[pilot active].freeze

    attribute :status, :string, default: 'prospect'
    attribute :carrier, :boolean, default: true
    attribute :investor, :boolean, default: false
    attribute :referral, :boolean, default: true
    attribute :referral_months, :integer, default: 6

    belongs_to :store, class_name: 'Spree::Store'
    has_many :shipping_methods, class_name: 'Spree::ShippingMethod', dependent: :nullify, inverse_of: :partner
    has_many :referred_sellers, class_name: 'Spree::Seller', foreign_key: :referred_by_partner_id,
                                dependent: :nullify, inverse_of: :referred_by_partner

    normalizes :code, with: ->(code) { code.to_s.strip.upcase }

    validates :name, :code, presence: true
    validates :code, uniqueness: { scope: [:store_id, *spree_base_uniqueness_scope] }, format: { with: /\A[A-Z0-9_-]{2,20}\z/ }
    validates :status, inclusion: { in: STATUSES }
    validates :parcel_cost, :investment_amount, :logistics_credit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :referral_commission_rate, :referral_gmv_share_rate, :equity_percent,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
    validate :volume_tiers_shape

    scope :live, -> { where(status: LIVE_STATUSES) }

    self.whitelisted_ransackable_attributes = %w[name code status carrier investor referral created_at]

    def self.find_by_referral_code(code)
      return nil if code.blank?

      live.where(referral: true).find_by(code: code.to_s.strip.upcase)
    end

    def live?
      LIVE_STATUSES.include?(status)
    end

    # Per-parcel cost for a monthly volume, using the best tier reached.
    def parcel_cost_for(parcels)
      tier = Array(volume_tiers).select { |t| parcels >= t['min_parcels'].to_i }.max_by { |t| t['min_parcels'].to_i }
      (tier ? tier['parcel_cost'] : parcel_cost).to_d
    end

    def next_tier_for(parcels)
      Array(volume_tiers).select { |t| t['min_parcels'].to_i > parcels }.min_by { |t| t['min_parcels'].to_i }
    end

    # Partner statement for a calendar month (defaults to the current month).
    # @return [Hash]
    def statement(month: Time.current)
      range = month.beginning_of_month..month.end_of_month
      shipments = partner_shipments.where(Spree::Order.table_name => { completed_at: range })
      parcels = shipments.count
      cost_rate = parcel_cost_for(parcels)
      parcel_costs = (parcels * cost_rate).round(2)
      delivery_revenue = shipments.sum(:cost).to_d

      referred_gmv = referred_paid_gmv(range)
      referral_share = (referred_gmv * referral_gmv_share_rate.to_d / 100).round(2)

      credit_before = [logistics_credit.to_d - parcel_costs_before(range.begin), 0].max
      credit_applied = [credit_before, parcel_costs].min

      {
        month: range.begin.to_date,
        currency: store.default_currency,
        parcels: parcels,
        parcel_cost_rate: cost_rate,
        next_tier: next_tier_for(parcels),
        delivery_revenue: delivery_revenue,
        parcel_costs: parcel_costs,
        delivery_margin: delivery_revenue - parcel_costs,
        referred_sellers: referred_sellers.count,
        referred_sellers_live: referred_sellers.approved.count,
        referred_gmv: referred_gmv,
        referral_share: referral_share,
        logistics_credit_applied: credit_applied,
        logistics_credit_remaining: credit_before - credit_applied,
        payable_to_partner: parcel_costs - credit_applied + referral_share
      }
    end

    private

    def partner_shipments
      Spree::Shipment.joins(:order, selected_shipping_rate: :shipping_method)
                     .merge(Spree::Order.complete)
                     .where(Spree::ShippingMethod.table_name => { partner_id: id })
                     .where(Spree::Order.table_name => { store_id: store_id })
    end

    def parcel_costs_before(time)
      counts = partner_shipments.where(Spree::Order.table_name => { completed_at: ...time })
                                .group(Arel.sql("DATE_TRUNC('month', #{Spree::Order.table_name}.completed_at)")).count
      counts.values.sum { |n| n * parcel_cost_for(n) }
    rescue ActiveRecord::StatementInvalid
      # databases without DATE_TRUNC (e.g. SQLite) — approximate with the base rate
      partner_shipments.where(Spree::Order.table_name => { completed_at: ...time }).count * parcel_cost.to_d
    end

    def referred_paid_gmv(range)
      Spree::LineItem.joins(:order, :seller)
                     .merge(Spree::Order.complete)
                     .where(Spree::Order.table_name => { payment_state: 'paid', completed_at: range, store_id: store_id })
                     .where(Spree::Seller.table_name => { referred_by_partner_id: id })
                     .where("#{Spree::Seller.table_name}.referral_expires_at IS NULL OR #{Spree::Seller.table_name}.referral_expires_at >= #{Spree::Order.table_name}.completed_at")
                     .sum('spree_line_items.price * spree_line_items.quantity').to_d
    end

    def volume_tiers_shape
      return if volume_tiers.blank?

      valid = volume_tiers.is_a?(Array) && volume_tiers.all? { |t| t.is_a?(Hash) && t['min_parcels'].to_i.positive? && t['parcel_cost'].to_d >= 0 }
      errors.add(:volume_tiers, :invalid) unless valid
    end
  end
end
