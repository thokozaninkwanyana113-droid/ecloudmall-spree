module Spree
  module Marketplace
    # Adds pickup-point data to the core Store API serializers in place (so every serializer that
    # embeds fulfillments/delivery methods — carts, orders — picks them up, including in eager-loaded
    # production processes where swapping Spree.api.* after boot would be too late).
    module SerializerExtensions
      def self.apply!
        extend_once(Spree::Api::V3::FulfillmentSerializer) do
          typelize pickup_point: ['PickupPoint', nullable: true], pickup_point_required: :boolean

          attribute :pickup_point do |shipment|
            shipment.current_pickup_point
          end

          attribute :pickup_point_required do |shipment|
            shipment.pickup_point_required?
          end
        end

        extend_once(Spree::Api::V3::DeliveryMethodSerializer) do
          typelize pickup_points: :boolean, partner: ['{ name: string; code: string } | null']

          attribute :pickup_points do |method|
            method.pickup_point?
          end

          attribute :partner do |method|
            method.partner && { name: method.partner.name, code: method.partner.code }
          end
        end
      end

      def self.extend_once(klass, &block)
        return if klass.instance_variable_get(:@marketplace_extended)

        klass.class_eval(&block)
        klass.instance_variable_set(:@marketplace_extended, true)
      end
    end
  end
end
