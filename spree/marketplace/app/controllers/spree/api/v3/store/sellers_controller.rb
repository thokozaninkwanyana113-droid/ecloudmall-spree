module Spree
  module Api
    module V3
      module Store
        # Public directory of approved marketplace sellers (SMMEs).
        #
        #   GET /api/v3/store/sellers
        #   GET /api/v3/store/sellers?q[province_eq]=GP&q[black_owned_eq]=true&sort=-approved_at
        #   GET /api/v3/store/sellers/:id_or_slug
        class SellersController < Store::ResourceController
          include Spree::Api::V3::HttpCaching

          protected

          def model_class
            Spree::Seller
          end

          def serializer_class
            Spree::Api::V3::SellerSerializer
          end

          def scope
            super.approved.with_attached_logo.with_attached_banner
          end

          def find_resource
            id = params[:id].to_s
            if id.start_with?('sel_')
              scope.find_by_prefix_id!(id)
            else
              scope.friendly.find(id)
            end
          end

          def apply_collection_sort(collection)
            return collection if sort_param.present?

            collection.order(featured: :desc, approved_at: :desc)
          end
        end
      end
    end
  end
end
