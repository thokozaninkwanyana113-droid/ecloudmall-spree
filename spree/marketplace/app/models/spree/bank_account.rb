module Spree
  # Where a seller or partner is paid. The full account number is encrypted when Active Record
  # encryption is configured; the admin only ever shows the last 4 digits.
  class BankAccount < Spree.base_class
    has_prefix_id :ba

    ACCOUNT_TYPES = %w[cheque savings transmission business].freeze
    # Universal branch codes of major South African banks (Payments Association of SA)
    BANKS = {
      'ABSA' => '632005', 'African Bank' => '430000', 'Bidvest Bank' => '462005', 'Capitec' => '470010',
      'Discovery Bank' => '679000', 'FNB' => '250655', 'Investec' => '580105', 'Nedbank' => '198765',
      'Standard Bank' => '051001', 'TymeBank' => '678910'
    }.freeze

    encrypts :account_number if Rails.configuration.active_record.encryption.include?(:primary_key)

    belongs_to :owner, polymorphic: true

    normalizes :account_number, with: ->(n) { n.to_s.gsub(/\D/, '') }
    normalizes :branch_code, with: ->(n) { n.to_s.gsub(/\D/, '') }

    validates :account_holder, :bank_name, presence: true
    validates :account_number, format: { with: /\A\d{6,16}\z/ }
    validates :branch_code, format: { with: /\A\d{6}\z/ }
    validates :account_type, inclusion: { in: ACCOUNT_TYPES }

    before_validation :set_last4
    before_save :reset_verification, if: -> { persisted? && (will_save_change_to_account_number? || will_save_change_to_branch_code?) }

    def verified?
      verified_at.present?
    end

    def verify!
      update!(verified_at: Time.current)
    end

    def masked_number
      "•••• #{account_number_last4}"
    end

    private

    def set_last4
      self.account_number_last4 = account_number.to_s.last(4)
    end

    # Changed bank details must be re-verified before any payout goes to them
    def reset_verification
      self.verified_at = nil
    end
  end
end
