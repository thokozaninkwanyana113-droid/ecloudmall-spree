module Spree
  module Admin
    # Marketplace → Partners: logistics / referral / investor partners (e.g. Paxi, Pargo),
    # their commercial terms and a monthly statement computed from real orders.
    class PartnersController < ResourceController
      private

      def build_resource
        current_store.partners.new
      end

      def collection_default_sort
        'name asc'
      end

      def permitted_resource_params
        permitted = params.require(:partner).permit(
          :name, :code, :status, :website, :description, :carrier, :investor, :referral,
          :parcel_cost, :volume_tiers_text, :referral_commission_rate, :referral_gmv_share_rate, :referral_months,
          :investment_amount, :equity_percent, :logistics_credit, :contact_name, :contact_email, :contact_phone,
          :notes, :signed_at
        )
        if permitted.key?(:volume_tiers_text)
          permitted[:volume_tiers] = parse_tiers(permitted.delete(:volume_tiers_text))
        end
        permitted
      end

      # "1000:42, 5000:38" → [{ "min_parcels" => 1000, "parcel_cost" => 42.0 }, ...]
      def parse_tiers(text)
        text.to_s.split(/[,\n]/).filter_map do |pair|
          min, cost = pair.split(':').map(&:strip)
          next if min.blank? || cost.blank?

          { 'min_parcels' => min.to_i, 'parcel_cost' => cost.to_f }
        end
      end
    end
  end
end
