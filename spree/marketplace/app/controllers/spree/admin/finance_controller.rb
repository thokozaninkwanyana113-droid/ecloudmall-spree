module Spree
  module Admin
    # Marketplace → Finance: what EcloudMall owes every seller and partner right now.
    class FinanceController < BaseController
      def show
        @currency = current_store.default_currency
        @payees = Spree::Marketplace::Ledger.payees(current_store).map do |payee|
          { payee: payee, available: payee.available_balance, pending: payee.pending_balance,
            payable: payee.payable_amount, ready: payee.payout_ready? }
        end.select { |row| row[:available].nonzero? || row[:pending].nonzero? }
           .sort_by { |row| -row[:available] }
        @batches = current_store_batches.order(created_at: :desc).limit(10)
        @recent_entries = Spree::LedgerEntry.where(store: current_store).includes(:payee, :order).order(created_at: :desc).limit(25)
      end

      def sync
        Spree::Marketplace::Ledger.sync_recent!(store: current_store, days: params.fetch(:days, 45).to_i)
        flash[:success] = Spree.t('marketplace.finance.synced')
        redirect_to spree.admin_finance_path, status: :see_other
      end

      private

      def model_class
        Spree::PayoutBatch
      end

      def current_store_batches
        Spree::PayoutBatch.where(store: current_store)
      end
    end
  end
end
