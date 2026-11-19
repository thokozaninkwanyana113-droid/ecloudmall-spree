module Spree
  module Api
    module V3
      module Store
        module Carts
          # PATCH /api/v3/store/carts/:cart_id/fulfillments/:fulfillment_id/pickup_point { pickup_point_id }
          # Validates the point with the provider and freezes it on the fulfillment.
          class PickupPointsController < Store::BaseController
            include Spree::Api::V3::CartResolvable
            include Spree::Api::V3::OrderLock

            before_action :find_cart!

            def update
              with_order_lock do
                fulfillment = @cart.shipments.find_by_prefix_id!(params[:fulfillment_id])
                provider = fulfillment.selected_shipping_rate&.shipping_method&.pickup_point_provider_instance
                unless provider
                  return render_error(code: 'pickup_points_unsupported',
                                      message: 'Select a pickup-point delivery option first', status: :unprocessable_content)
                end

                option = provider.find_by_external_id(params[:pickup_point_id])
                return render_error(code: 'pickup_point_not_found', message: 'That pickup point is not available', status: :not_found) unless option

                fulfillment.select_pickup_point!(option)
                render_cart
              end
            end
          end
        end
      end
    end
  end
end
