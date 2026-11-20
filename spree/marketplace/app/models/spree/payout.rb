module Spree
  # One transfer to one payee inside a payout run, with its bank details snapshotted.
  class Payout < Spree.base_class
    has_prefix_id :po

    STATUSES = %w[pending paid failed canceled].freeze

    encrypts :bank_account_number if Rails.configuration.active_record.encryption.include?(:primary_key)

    belongs_to :payout_batch, class_name: 'Spree::PayoutBatch', inverse_of: :payouts
    belongs_to :payee, polymorphic: true

    attribute :status, :string, default: 'pending'

    validates :amount, numericality: { greater_than: 0 }
    validates :status, inclusion: { in: STATUSES }
    validates :reference, presence: true, uniqueness: true
    validates :bank_account_number, presence: true

    before_validation :set_reference, on: :create

    delegate :store, to: :payout_batch

    def self.build_for(batch, payee, amount)
      bank = payee.bank_account
      batch.payouts.new(
        payee: payee, amount: amount, currency: batch.currency,
        bank_account_holder: bank.account_holder, bank_name: bank.bank_name, bank_branch_code: bank.branch_code,
        bank_account_number: bank.account_number, bank_account_last4: bank.account_number_last4,
        bank_account_type: bank.account_type
      )
    end

    # Shown on the payee's bank statement (max 20 chars for most SA banks)
    def beneficiary_reference
      "ECLOUDMALL #{reference}".first(20)
    end

    def mark_paid!
      return self if status == 'paid'
      raise ArgumentError, "Payout #{reference} is #{status}, only pending payouts can be paid" unless status == 'pending'

      transaction do
        update!(status: 'paid', paid_at: Time.current)
        Spree::LedgerEntry.record!(
          idempotency_key: "payout:#{id}", store: store, payee: payee, kind: 'payout', amount: -amount,
          currency: currency, available_at: Time.current, source: self, description: "Payout #{reference}"
        )
      end
      publish_event('payout.paid') if respond_to?(:publish_event)
      self
    end

    # A transfer the bank bounced. If it had been marked paid, the money is owed to the payee again.
    def mark_failed!(reason)
      transaction do
        was_paid = status == 'paid'
        update!(status: 'failed', failure_reason: reason)
        if was_paid
          Spree::LedgerEntry.record!(
            idempotency_key: "payout_reversal:#{id}", store: store, payee: payee, kind: 'payout_reversal', amount: amount,
            currency: currency, available_at: Time.current, source: self, description: "Payout #{reference} failed: #{reason}"
          )
        end
      end
      payout_batch.recalculate_totals!
      self
    end

    private

    def set_reference
      self.reference ||= "#{payee.class.name.demodulize.first(3).upcase}#{SecureRandom.alphanumeric(8).upcase}"
    end
  end
end
