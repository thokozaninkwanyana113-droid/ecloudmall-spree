module Spree
  module Api
    module V3
      # Store API serializer for marketplace sellers (SMMEs)
      class SellerSerializer < BaseSerializer
        typelize name: :string, slug: :string, tagline: [:string, nullable: true],
                 description: [:string, nullable: true], story_headline: [:string, nullable: true], story: [:string, nullable: true],
                 province: [:string, nullable: true], province_name: [:string, nullable: true],
                 city: [:string, nullable: true], township: [:string, nullable: true], location: :string,
                 business_type: [:string, nullable: true], business_type_name: [:string, nullable: true],
                 primary_category: [:string, nullable: true],
                 bbbee_level: [:number, nullable: true],
                 black_owned: :boolean, women_owned: :boolean, youth_owned: :boolean,
                 disability_owned: :boolean, township_business: :boolean,
                 featured: :boolean, verified: :boolean,
                 founded_year: [:number, nullable: true], team_size: [:number, nullable: true],
                 brand_color: [:string, nullable: true],
                 ships_nationwide: :boolean, offers_collection: :boolean, dispatch_days: [:number, nullable: true],
                 website: [:string, nullable: true], instagram: [:string, nullable: true],
                 facebook: [:string, nullable: true], tiktok: [:string, nullable: true], whatsapp: [:string, nullable: true],
                 badges: [:string, multi: true],
                 products_count: :number,
                 logo_url: [:string, nullable: true], banner_url: [:string, nullable: true],
                 approved_at: [:string, nullable: true]

        attributes :name, :slug, :tagline, :description, :story_headline, :story,
                   :province, :province_name, :city, :township, :location,
                   :business_type, :business_type_name, :primary_category, :bbbee_level,
                   :black_owned, :women_owned, :youth_owned, :disability_owned, :township_business,
                   :featured, :verified, :founded_year, :team_size, :brand_color,
                   :ships_nationwide, :offers_collection, :dispatch_days,
                   :website, :instagram, :facebook, :tiktok, :whatsapp,
                   :badges,
                   approved_at: :iso8601

        attribute :products_count do |seller|
          seller.active_products.count
        end

        attribute :logo_url do |seller|
          image_url_for(seller.logo)
        end

        attribute :banner_url do |seller|
          image_url_for(seller.banner)
        end
      end
    end
  end
end
