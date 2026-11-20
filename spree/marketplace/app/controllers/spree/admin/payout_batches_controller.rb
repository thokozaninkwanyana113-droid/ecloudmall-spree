module Spree
  module Admin
    # Payout runs: draft (computed from available balances) → approved → bank CSV exported → paid.
    class PayoutBatchesController < BaseController
      before_action :load_batch, except: %i[index create]

      def index
        @batches = Spree::PayoutBatch.where(store: current_store).order(created_at: :desc)
      end

      def show
        @payouts = @batch.payouts.includes(:payee).order(amount: :desc)
        @blocked = Spree::Marketplace::Ledger.blocked_payees(current_store)
      end

      def create
        batch = Spree::Marketplace::Ledger.create_payout_batch!(store: current_store)
        flash[:success] = Spree.t('marketplace.finance.batch_created', count: batch.payouts_count.to_i)
        redirect_to spree.admin_payout_batch_path(batch), status: :see_other
      end

      def approve
        transition(:approve)
      end

      def cancel
        transition(:cancel)
      end

      def mark_paid
        @batch.mark_paid!
        flash[:success] = Spree.t('marketplace.finance.batch_paid')
        redirect_to spree.admin_payout_batch_path(@batch), status: :see_other
      rescue StateMachines::InvalidTransition, ArgumentError => e
        flash[:error] = e.message
        redirect_to spree.admin_payout_batch_path(@batch), status: :see_other
      end

      # Bank bulk-payment file
      def export
        unless @batch.can_export?
          flash[:error] = Spree.t('marketplace.finance.approve_first')
          return redirect_to spree.admin_payout_batch_path(@batch), status: :see_other
        end

        @batch.export!
        send_data @batch.to_bank_csv, filename: "ecloudmall-payouts-#{@batch.number}.csv", type: 'text/csv'
      end

      private

      def load_batch
        @batch = Spree::PayoutBatch.where(store: current_store).find_by_prefix_id!(params[:id])
      end

      def transition(event)
        if @batch.public_send(event)
          flash[:success] = Spree.t("marketplace.finance.batch_#{event}")
        else
          flash[:error] = Spree.t('marketplace.finance.transition_failed', status: @batch.status)
        end
        redirect_to spree.admin_payout_batch_path(@batch), status: :see_other
      end

      def model_class
        Spree::PayoutBatch
      end
    end
  end
end
