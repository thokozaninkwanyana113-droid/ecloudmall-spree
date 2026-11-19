module Spree
  module Api
    module V3
      module Store
        # "Sell on EcloudMall" — public onboarding endpoint for SMMEs.
        #
        #   POST /api/v3/store/seller_applications
        #
        # Creates a seller in the `pending` state. Marketplace staff review and
        # approve applications in the admin dashboard (Marketplace → Sellers).
        class SellerApplicationsController < Store::BaseController
          PERMITTED = %i[
            name tagline description story contact_name email phone whatsapp website instagram facebook tiktok
            province city township business_type size_band registration_number vat_number bbbee_level
            black_owned women_owned youth_owned disability_owned township_business primary_category
            founded_year team_size ships_nationwide offers_collection
          ].freeze

          def create
            seller = current_store.sellers.new(params.permit(*PERMITTED))
            seller.status = 'pending'
            authorize!(:create, seller)

            if seller.save
              seller.publish_event('seller.applied') if seller.respond_to?(:publish_event)
              render json: {
                id: seller.prefixed_id,
                name: seller.name,
                slug: seller.slug,
                status: seller.status,
                message: Spree.t('marketplace.application_received', name: seller.name)
              }, status: :created
            else
              render_errors(seller.errors)
            end
          end
        end
      end
    end
  end
end
