module Spree
  module Api
    module V3
      module Store
        # GET /api/v3/store/delivery_methods/:delivery_method_id/pickup_points?postal_code=&city=&q=
        # Ephemeral pickup points from the delivery method's PickupPointProvider (e.g. Paxi, Pargo).
        class PickupPointsController < Store::BaseController
          def index
            delivery_method = Spree::ShippingMethod.find_by_prefix_id!(params[:delivery_method_id])
            provider = delivery_method.pickup_point_provider_instance
            return render_error(code: 'pickup_points_unsupported', message: 'This delivery method has no pickup points', status: :unprocessable_content) unless provider

            points = provider.find_nearby(
              postal_code: params[:postal_code], city: params[:city], query: params[:q],
              limit: params.fetch(:limit, 10).to_i.clamp(1, 50)
            )
            render json: { data: points.map(&:as_json), meta: { count: points.size } }
          end
        end
      end
    end
  end
end
