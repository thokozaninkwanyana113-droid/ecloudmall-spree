module Spree
  module Admin
    # A single payout the bank bounced (wrong details, closed account).
    class PayoutsController < BaseController
      def mark_failed
        payout = Spree::Payout.joins(:payout_batch).where(spree_payout_batches: { store_id: current_store.id }).find_by_prefix_id!(params[:id])
        payout.mark_failed!(params[:failure_reason].presence || 'Rejected by bank')
        flash[:success] = Spree.t('marketplace.finance.payout_failed', reference: payout.reference)
        redirect_to spree.admin_payout_batch_path(payout.payout_batch), status: :see_other
      end

      private

      def model_class
        Spree::Payout
      end
    end
  end
end
