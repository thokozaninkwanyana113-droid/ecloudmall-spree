module Spree
  # Append-only record of money EcloudMall owes a payee (seller or partner).
  # Positive amount = owed to the payee; negative = owed back / paid out.
  # Never update or delete entries — write a correcting entry (docs/plans/ecloudmall-funds-flow.md).
  class LedgerEntry < Spree.base_class
    has_prefix_id :le

    KINDS = %w[sale commission refund commission_reversal parcel_costs referral_share payout payout_reversal adjustment].freeze

    belongs_to :store, class_name: 'Spree::Store'
    belongs_to :payee, polymorphic: true
    belongs_to :order, class_name: 'Spree::Order', optional: true
    belongs_to :source, polymorphic: true, optional: true

    validates :kind, inclusion: { in: KINDS }
    validates :amount, :currency, :available_at, :idempotency_key, presence: true
    validates :idempotency_key, uniqueness: true

    scope :available, ->(at = Time.current) { where(available_at: ..at) }
    scope :pending, ->(at = Time.current) { where('available_at > ?', at) }
    scope :for_payee, ->(payee) { where(payee: payee) }

    self.whitelisted_ransackable_attributes = %w[kind payee_type created_at available_at]

    before_update { raise ActiveRecord::ReadOnlyRecord, 'Ledger entries are append-only' }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, 'Ledger entries are append-only' }

    # Idempotent write: returns the existing entry when the key was already recorded.
    def self.record!(idempotency_key:, **attrs)
      find_by(idempotency_key: idempotency_key) || create!(idempotency_key: idempotency_key, **attrs)
    rescue ActiveRecord::RecordNotUnique
      find_by!(idempotency_key: idempotency_key)
    end
  end
end
