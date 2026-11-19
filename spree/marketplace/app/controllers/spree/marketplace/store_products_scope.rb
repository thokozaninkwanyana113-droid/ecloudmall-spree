module Spree
  module Marketplace
    # Hides products belonging to sellers that are not (or no longer) approved
    # from the Store API catalog.
    module StoreProductsScope
      protected

      def scope
        super.from_approved_sellers
      end
    end
  end
end
