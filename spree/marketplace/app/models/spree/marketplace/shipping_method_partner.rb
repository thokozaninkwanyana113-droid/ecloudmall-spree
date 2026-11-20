module Spree
  module Marketplace
    # Delivery methods can belong to a logistics partner and expose third-party pickup points
    # through a PickupPointProvider (see docs/plans/6.0-fulfillment-and-delivery.md).
    module ShippingMethodPartner
      extend ActiveSupport::Concern

      included do
        belongs_to :partner, class_name: 'Spree::Partner', optional: true, inverse_of: :shipping_methods
      end

      def pickup_point?
        pickup_point_provider.present?
      end

      def pickup_point_provider_instance
        return nil unless pickup_point?

        pickup_point_provider.constantize.new(self)
      end
    end
  end
end
