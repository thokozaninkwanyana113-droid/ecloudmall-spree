module Spree
  module Api
    module V3
      # Compact seller representation embedded in product payloads
      class SellerSummarySerializer < BaseSerializer
        typelize name: :string, slug: :string, tagline: [:string, nullable: true],
                 province: [:string, nullable: true], province_name: [:string, nullable: true],
                 city: [:string, nullable: true], location: :string, brand_color: [:string, nullable: true],
                 verified: :boolean, badges: [:string, multi: true], logo_url: [:string, nullable: true],
                 dispatch_days: [:number, nullable: true]

        attributes :name, :slug, :tagline, :province, :province_name, :city, :location,
                   :brand_color, :verified, :badges, :dispatch_days

        attribute :logo_url do |seller|
          image_url_for(seller.logo)
        end
      end
    end
  end
end
