module Spree
  # A Seller is an SMME (small, medium or micro enterprise) selling on the marketplace.
  #
  # Sellers are created in the `pending` state when a business applies to sell
  # (via the Store API `POST /api/v3/store/seller_applications`) and must be
  # approved by marketplace staff before they appear in the storefront.
  class Seller < Spree.base_class
    acts_as_paranoid

    include Spree::SingleStoreResource
    include Spree::Metafields if defined?(Spree::Metafields)

    extend FriendlyId
    friendly_id :slug_candidates, use: [:slugged, :scoped, :history], scope: :store_id

    has_prefix_id :sel

    STATUSES = %w[pending approved rejected suspended].freeze
    PUBLIC_STATUSES = %w[approved].freeze
    SLUG_RESERVED = %w[apply new sell].freeze

    attribute :black_owned, :boolean, default: false
    attribute :women_owned, :boolean, default: false
    attribute :youth_owned, :boolean, default: false
    attribute :disability_owned, :boolean, default: false
    attribute :township_business, :boolean, default: false
    attribute :ships_nationwide, :boolean, default: true
    attribute :offers_collection, :boolean, default: false
    attribute :featured, :boolean, default: false
    attribute :verified, :boolean, default: false
    attribute :dispatch_days, :integer, default: 2
    attribute :status, :string, default: 'pending'

    belongs_to :store, class_name: 'Spree::Store'
    has_many :products, class_name: 'Spree::Product', dependent: :nullify, inverse_of: :seller
    has_many :line_items, class_name: 'Spree::LineItem', dependent: :nullify, inverse_of: :seller

    has_one_attached :logo, service: Spree.public_storage_service_name
    has_one_attached :banner, service: Spree.public_storage_service_name

    normalizes :email, with: ->(email) { email.to_s.strip.downcase }
    normalizes :province, with: ->(province) { province.to_s.strip.upcase.presence }

    validates :name, presence: true, length: { maximum: 120 }
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :status, inclusion: { in: STATUSES }
    validates :province, inclusion: { in: Spree::Marketplace::PROVINCES.keys }, allow_blank: true
    validates :business_type, inclusion: { in: Spree::Marketplace::BUSINESS_TYPES.keys }, allow_blank: true
    validates :size_band, inclusion: { in: Spree::Marketplace::SIZE_BANDS.keys }, allow_blank: true
    validates :bbbee_level, numericality: { only_integer: true, in: 1..8 }, allow_nil: true
    validates :commission_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
    validates :founded_year, numericality: { only_integer: true, greater_than: 1900, less_than_or_equal_to: ->(_) { Date.current.year } }, allow_nil: true
    validates :brand_color, format: { with: /\A#[0-9a-fA-F]{6}\z/ }, allow_blank: true
    validates :description, length: { maximum: 5000 }
    validates :tagline, length: { maximum: 160 }
    validate :name_not_already_taken, on: :create

    before_validation :set_default_commission_rate, on: :create

    scope :approved, -> { where(status: 'approved') }
    scope :pending, -> { where(status: 'pending') }
    scope :featured, -> { where(featured: true) }
    scope :in_province, ->(code) { where(province: code.to_s.upcase) }

    self.whitelisted_ransackable_attributes = %w[name slug status province city primary_category business_type
                                                 black_owned women_owned youth_owned disability_owned township_business
                                                 featured verified bbbee_level created_at approved_at]
    self.whitelisted_ransackable_associations = %w[products]

    state_machine :status, initial: :pending do
      event :approve do
        transition [:pending, :rejected, :suspended] => :approved
      end
      after_transition to: :approved do |seller|
        seller.update_columns(approved_at: Time.current, rejected_at: nil, rejection_reason: nil)
      end

      event :reject do
        transition pending: :rejected
      end
      after_transition to: :rejected do |seller|
        seller.update_columns(rejected_at: Time.current)
      end

      event :suspend do
        transition approved: :suspended
      end
    end

    def province_name
      Spree::Marketplace::PROVINCES[province]
    end

    def business_type_name
      Spree::Marketplace::BUSINESS_TYPES[business_type]
    end

    def location
      [township, city, province_name].compact_blank.uniq.join(', ')
    end

    # Ownership / impact badges displayed on the storefront
    def badges
      list = []
      list << 'black_owned' if black_owned?
      list << 'women_owned' if women_owned?
      list << 'youth_owned' if youth_owned?
      list << 'disability_owned' if disability_owned?
      list << 'township_business' if township_business?
      list << "bbbee_level_#{bbbee_level}" if bbbee_level.present?
      list << 'verified' if verified?
      list
    end

    def active_products
      products.where(status: 'active')
    end

    def commission_rate_or_default
      (commission_rate || Spree::Marketplace::DEFAULT_COMMISSION_RATE).to_d
    end

    # Sales of this seller's items across completed orders.
    # Payouts are only due on orders that have been paid in full.
    # @return [Hash] gross, commission and payout amounts plus counts
    def sales_summary(currency: store&.default_currency)
      items = line_items.joins(:order).merge(Spree::Order.complete).where(currency: currency)
      paid_items = items.where(Spree::Order.table_name => { payment_state: 'paid' })
      amount_sql = 'spree_line_items.price * spree_line_items.quantity'
      gross = items.sum(amount_sql).to_d
      paid_gross = paid_items.sum(amount_sql).to_d
      commission = (paid_gross * commission_rate_or_default / 100).round(2)
      {
        currency: currency,
        orders_count: items.distinct.count(:order_id),
        units_sold: items.sum(:quantity),
        gross: gross,
        awaiting_payment: gross - paid_gross,
        commission: commission,
        payout: paid_gross - commission
      }
    end

    def should_generate_new_friendly_id?
      slug.blank? || (name_changed? && !persisted?)
    end

    private

    def slug_candidates
      [
        :name,
        [:name, :city],
        [:name, :city, :province]
      ]
    end

    def set_default_commission_rate
      self.commission_rate ||= Spree::Marketplace::DEFAULT_COMMISSION_RATE
    end

    def name_not_already_taken
      return if name.blank? || store.blank?

      if self.class.where(store_id: store_id).where('LOWER(name) = ?', name.downcase).exists?
        errors.add(:name, :taken)
      end
    end
  end
end
