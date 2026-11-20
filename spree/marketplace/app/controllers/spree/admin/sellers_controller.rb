module Spree
  module Admin
    # Marketplace → Sellers: review SMME applications, approve/reject/suspend
    # sellers and track their sales, commission and payouts.
    class SellersController < ResourceController
      before_action :load_form_data, only: %i[new edit create update]

      def approve
        transition!(:approve)
      end

      def reject
        @object.rejection_reason = params[:rejection_reason] if params[:rejection_reason].present?
        transition!(:reject)
      end

      def suspend
        transition!(:suspend)
      end

      private

      def transition!(event)
        authorize! :update, @object

        if @object.public_send("#{event}")
          flash[:success] = Spree.t("marketplace.admin.seller_#{event}d", name: @object.name)
        else
          flash[:error] = Spree.t('marketplace.admin.transition_failed', status: @object.status)
        end
        redirect_to edit_object_url(@object), status: :see_other
      end

      def load_form_data
        @provinces = Spree::Marketplace::PROVINCES.map { |code, name| [name, code] }
        @business_types = Spree::Marketplace::BUSINESS_TYPES.map { |code, name| [name, code] }
        @size_bands = Spree::Marketplace::SIZE_BANDS.map { |code, name| [name, code] }
      end

      def collection_default_sort
        'created_at desc'
      end

      def build_resource
        current_store.sellers.new
      end

      def permitted_resource_params
        params.require(:seller).permit(
          :name, :slug, :tagline, :description, :story_headline, :story,
          :contact_name, :email, :phone, :whatsapp, :website, :instagram, :facebook, :tiktok,
          :province, :city, :township, :business_type, :size_band, :registration_number, :vat_number,
          :bbbee_level, :black_owned, :women_owned, :youth_owned, :disability_owned, :township_business,
          :primary_category, :founded_year, :team_size, :brand_color,
          :ships_nationwide, :offers_collection, :dispatch_days,
          :commission_rate, :featured, :verified, :admin_notes, :logo, :banner,
          :referred_by_partner_id, :referral_expires_at
        )
      end
    end
  end
end
