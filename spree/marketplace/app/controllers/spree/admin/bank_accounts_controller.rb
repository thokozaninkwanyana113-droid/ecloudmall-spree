module Spree
  module Admin
    # Bank details for a seller or partner. Changing the account number un-verifies it, so a payout can
    # never go to new details that nobody has checked.
    class BankAccountsController < BaseController
      before_action :load_owner

      def update
        account = @owner.bank_account || @owner.build_bank_account
        attrs = params.require(:bank_account).permit(:account_holder, :bank_name, :branch_code, :account_number, :account_type)
        attrs.delete(:account_number) if attrs[:account_number].blank? && account.persisted?
        if account.update(attrs)
          flash[:success] = Spree.t('marketplace.finance.bank_saved')
        else
          flash[:error] = account.errors.full_messages.to_sentence
        end
        redirect_back fallback_location: owner_path, status: :see_other
      end

      def verify
        @owner.bank_account&.verify!
        flash[:success] = Spree.t('marketplace.finance.bank_verified')
        redirect_back fallback_location: owner_path, status: :see_other
      end

      private

      def load_owner
        @owner = if params[:seller_id]
                   current_store.sellers.friendly.find(params[:seller_id])
                 else
                   current_store.partners.find_by_prefix_id!(params[:partner_id])
                 end
      end

      def owner_path
        @owner.is_a?(Spree::Seller) ? spree.edit_admin_seller_path(@owner) : spree.edit_admin_partner_path(@owner)
      end

      def model_class
        Spree::BankAccount
      end
    end
  end
end
