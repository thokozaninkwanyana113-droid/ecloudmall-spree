module Spree
  module Marketplace
    class Engine < Rails::Engine
      isolate_namespace Spree
      engine_name 'spree_marketplace'

      config.autoload_paths += %W[#{config.root}/lib]

      initializer 'spree_marketplace.permitted_attributes' do
        Spree::PermittedAttributes.product_attributes << :seller_id unless Spree::PermittedAttributes.product_attributes.include?(:seller_id)
      end

      config.to_prepare do
        Spree::Product.include(Spree::Marketplace::ProductSeller) unless Spree::Product.include?(Spree::Marketplace::ProductSeller)
        Spree::Store.include(Spree::Marketplace::StoreSellers) unless Spree::Store.include?(Spree::Marketplace::StoreSellers)
        Spree::LineItem.include(Spree::Marketplace::LineItemSeller) unless Spree::LineItem.include?(Spree::Marketplace::LineItemSeller)
        Spree::Api::V3::Store::ProductsController.prepend(Spree::Marketplace::StoreProductsScope) unless Spree::Api::V3::Store::ProductsController <= Spree::Marketplace::StoreProductsScope
      end

      config.after_initialize do
        Spree.permissions.assign(:default, [Spree::PermissionSets::MarketplaceCustomer])

        Spree.api.product_serializer = 'Spree::Api::V3::MarketplaceProductSerializer'

        Spree.admin.partials.product_form_sidebar << 'spree/admin/products/marketplace/seller'
      end
    end
  end
end
