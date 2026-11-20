module Spree
  module Marketplace
    # Anything EcloudMall pays out to (sellers, partners): ledger, balances and a bank account.
    module Payee
      extend ActiveSupport::Concern

      included do
        has_many :ledger_entries, class_name: 'Spree::LedgerEntry', as: :payee, dependent: :restrict_with_error
        has_many :payouts, class_name: 'Spree::Payout', as: :payee, dependent: :restrict_with_error
        has_one :bank_account, class_name: 'Spree::BankAccount', as: :owner, dependent: :destroy
      end

      def balance(currency: store.default_currency)
        ledger_entries.where(currency: currency).sum(:amount).to_d
      end

      def available_balance(currency: store.default_currency, at: Time.current)
        ledger_entries.where(currency: currency).available(at).sum(:amount).to_d
      end

      def pending_balance(currency: store.default_currency, at: Time.current)
        ledger_entries.where(currency: currency).pending(at).sum(:amount).to_d
      end

      # Amount that can go into a payout run now: available balance less anything already in an unpaid payout.
      def payable_amount(currency: store.default_currency, at: Time.current)
        in_flight = payouts.where(currency: currency, status: 'pending').sum(:amount).to_d
        [available_balance(currency: currency, at: at) - in_flight, 0].max
      end

      def payout_ready?
        bank_account&.verified? || false
      end
    end
  end
end
