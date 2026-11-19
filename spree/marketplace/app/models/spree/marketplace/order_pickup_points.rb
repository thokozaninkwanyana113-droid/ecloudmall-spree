module Spree
  module Marketplace
    module OrderPickupPoints
      extend ActiveSupport::Concern

      included do
        validate :pickup_points_selected, if: -> { will_save_change_to_state? && state == 'complete' }
      end

      def missing_pickup_point?
        shipments.any?(&:pickup_point_missing?)
      end

      private

      def pickup_points_selected
        errors.add(:base, Spree.t('marketplace.pickup_points.required')) if missing_pickup_point?
      end
    end
  end
end
