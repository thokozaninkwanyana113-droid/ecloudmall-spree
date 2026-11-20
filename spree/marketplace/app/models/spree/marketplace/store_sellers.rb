module Spree
  module Marketplace
    module StoreSellers
      extend ActiveSupport::Concern

      included do
        has_many :sellers, class_name: 'Spree::Seller', dependent: :destroy, inverse_of: :store
        has_many :partners, class_name: 'Spree::Partner', dependent: :destroy, inverse_of: :store
      end
    end
  end
end
