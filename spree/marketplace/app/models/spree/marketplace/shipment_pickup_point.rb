module Spree
  module Marketplace
    # Frozen snapshot of the third-party pickup point a customer chose for a fulfillment.
    module ShipmentPickupPoint
      extend ActiveSupport::Concern

      def pickup_point_method
        method = selected_shipping_rate&.shipping_method
        method if method&.pickup_point?
      end

      def pickup_point_required?
        pickup_point_method.present?
      end

      # The stored point, only while it still belongs to the selected delivery method's provider
      def current_pickup_point
        method = pickup_point_method
        return nil if method.nil? || pickup_point_data.blank?

        provider = method.pickup_point_provider_instance.provider_code
        pickup_point_data if pickup_point_data['provider'] == provider
      end

      def pickup_point_missing?
        pickup_point_required? && current_pickup_point.nil?
      end

      # @param option [Spree::PickupPointOption]
      def select_pickup_point!(option)
        # Shipment#update! is Spree's state recalculation, not ActiveRecord#update!
        update_columns(pickup_point_data: option.to_h.deep_stringify_keys, updated_at: Time.current)
        order.touch
      end
    end
  end
end
