module Spree
  module Marketplace
    class Engine < Rails::Engine
      isolate_namespace Spree
      engine_name 'spree_marketplace'

      config.autoload_paths += %W[#{config.root}/lib]

      initializer 'spree_marketplace.permitted_attributes' do
        Spree::PermittedAttributes.product_attributes << :seller_id unless Spree::PermittedAttributes.product_attributes.include?(:seller_id)
      end

      GATEWAYS = %w[Spree::Gateway::Payfast Spree::Gateway::Ozow Spree::Gateway::Yoco].freeze

      config.to_prepare do
        # Re-register SA gateways after code reloads (core sets the list in after_initialize)
        Spree::Marketplace::Engine.register_gateways if Spree.payment_methods

        Spree::Product.include(Spree::Marketplace::ProductSeller) unless Spree::Product.include?(Spree::Marketplace::ProductSeller)
        Spree::Store.include(Spree::Marketplace::StoreSellers) unless Spree::Store.include?(Spree::Marketplace::StoreSellers)
        Spree::LineItem.include(Spree::Marketplace::LineItemSeller) unless Spree::LineItem.include?(Spree::Marketplace::LineItemSeller)
        Spree::ShippingMethod.include(Spree::Marketplace::ShippingMethodPartner) unless Spree::ShippingMethod.include?(Spree::Marketplace::ShippingMethodPartner)
        Spree::Shipment.include(Spree::Marketplace::ShipmentPickupPoint) unless Spree::Shipment.include?(Spree::Marketplace::ShipmentPickupPoint)
        Spree::Order.include(Spree::Marketplace::OrderPickupPoints) unless Spree::Order.include?(Spree::Marketplace::OrderPickupPoints)
        Spree::Marketplace::SerializerExtensions.apply!
        Spree::Api::V3::Store::ProductsController.prepend(Spree::Marketplace::StoreProductsScope) unless Spree::Api::V3::Store::ProductsController <= Spree::Marketplace::StoreProductsScope
      end

      def self.register_gateways
        Spree.payment_methods = Spree.payment_methods.reject { |klass| GATEWAYS.include?(klass.name) } + GATEWAYS.map(&:constantize)
      end

      config.after_initialize do
        Spree::Marketplace::Engine.register_gateways

        Spree.permissions.assign(:default, [Spree::PermissionSets::MarketplaceCustomer])

        Spree.api.product_serializer = 'Spree::Api::V3::MarketplaceProductSerializer'

        Spree.admin.partials.product_form_sidebar << 'spree/admin/products/marketplace/seller'
      end
    end
  end
end
