module Spree
  module PermissionSets
    # Storefront permissions for the marketplace:
    # anyone can browse approved sellers and apply to become a seller.
    class MarketplaceCustomer < Base
      def activate!
        can :read, Spree::Seller, status: 'approved'
        can :create, Spree::Seller
      end
    end
  end
end
