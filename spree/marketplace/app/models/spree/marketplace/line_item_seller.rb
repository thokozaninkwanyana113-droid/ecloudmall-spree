module Spree
  module Marketplace
    # Snapshots the selling seller onto each line item so marketplace sales,
    # commission and payouts stay correct even if a product later changes seller.
    module LineItemSeller
      extend ActiveSupport::Concern

      included do
        belongs_to :seller, class_name: 'Spree::Seller', optional: true, inverse_of: :line_items

        before_validation :assign_seller_from_product, on: :create
      end

      private

      def assign_seller_from_product
        self.seller_id ||= variant&.product&.seller_id
      end
    end
  end
end
