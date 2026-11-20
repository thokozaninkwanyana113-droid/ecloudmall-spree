module Spree
  module Api
    module V3
      # Store API product serializer with the selling seller attached.
      # Always includes a compact `seller` object (null for house products) so
      # listing cards can show "sold by" without extra requests.
      class MarketplaceProductSerializer < ProductSerializer
        typelize seller_id: [:string, nullable: true], seller: ['SellerSummary', nullable: true]

        attribute :seller_id do |product|
          product.seller&.prefixed_id
        end

        attribute :seller do |product|
          next if product.seller.nil?

          Spree::Api::V3::SellerSummarySerializer.new(product.seller, params: params).to_h
        end
      end
    end
  end
end
