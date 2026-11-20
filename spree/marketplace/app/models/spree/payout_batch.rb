require 'csv'

module Spree
  # A payout run: one bank batch paying every seller and partner whose available balance is due.
  class PayoutBatch < Spree.base_class
    has_prefix_id :pob

    MINIMUM_PAYOUT = 100

    belongs_to :store, class_name: 'Spree::Store'
    has_many :payouts, class_name: 'Spree::Payout', dependent: :destroy, inverse_of: :payout_batch

    attribute :status, :string, default: 'draft'

    validates :number, :currency, :period_end, presence: true
    validates :number, uniqueness: true

    before_validation :set_number, on: :create

    state_machine :status, initial: :draft do
      event :approve do
        transition draft: :approved, if: ->(batch) { batch.payouts.where(status: 'pending').exists? }
      end
      after_transition to: :approved do |batch|
        batch.update_columns(approved_at: Time.current)
      end

      event :export do
        transition [:approved, :exported] => :exported
      end
      after_transition to: :exported do |batch|
        batch.update_columns(exported_at: Time.current)
      end

      event :complete do
        transition [:approved, :exported] => :paid
      end
      after_transition to: :paid do |batch|
        batch.update_columns(paid_at: Time.current)
      end

      event :cancel do
        transition [:draft, :approved, :exported] => :canceled
      end
      after_transition to: :canceled do |batch|
        batch.payouts.where(status: 'pending').update_all(status: 'canceled', updated_at: Time.current)
      end
    end

    def recalculate_totals!
      update_columns(total: payouts.where.not(status: 'canceled').sum(:amount), payouts_count: payouts.where.not(status: 'canceled').count)
    end

    # Marks every pending payout paid (writes the ledger debits) and closes the batch.
    def mark_paid!
      transaction do
        payouts.where(status: 'pending').find_each(&:mark_paid!)
        complete!
      end
    end

    # Generic South African bank bulk-payment CSV (columns accepted by the major banks' import templates).
    def to_bank_csv
      ::CSV.generate do |csv|
        csv << ['Beneficiary name', 'Bank', 'Branch code', 'Account number', 'Account type', 'Amount', 'Beneficiary reference', 'Own reference']
        payouts.where(status: 'pending').includes(:payee).find_each do |payout|
          csv << [payout.bank_account_holder, payout.bank_name, payout.bank_branch_code, payout.bank_account_number,
                  payout.bank_account_type, format('%.2f', payout.amount), payout.beneficiary_reference, payout.reference]
        end
      end
    end

    private

    def set_number
      self.number ||= "PO#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.alphanumeric(4).upcase}"
    end
  end
end
