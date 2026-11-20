module Spree
  module Marketplace
    module ProductSeller
      extend ActiveSupport::Concern

      included do
        belongs_to :seller, class_name: 'Spree::Seller', optional: true, inverse_of: :products, touch: true

        scope :for_seller, ->(seller) { where(seller_id: seller.id) }
        scope :from_approved_sellers, -> { where(seller_id: nil).or(where(seller_id: Spree::Seller.approved.select(:id))) }

        self.whitelisted_ransackable_associations = (whitelisted_ransackable_associations || []) | %w[seller]
        self.whitelisted_ransackable_attributes = (whitelisted_ransackable_attributes || []) | %w[seller_id]
      end
    end
  end
end
