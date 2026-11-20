module Spree
  module PickupPointProvider
    class Base
      attr_reader :delivery_method

      def initialize(delivery_method)
        @delivery_method = delivery_method
      end

      def partner
        delivery_method.partner
      end

      def provider_code
        partner&.code&.downcase || self.class.name.demodulize.underscore
      end

      # @return [Array<Spree::PickupPointOption>]
      def find_nearby(postal_code: nil, city: nil, query: nil, limit: 10)
        raise NotImplementedError
      end

      # @return [Spree::PickupPointOption, nil]
      def find_by_external_id(external_id)
        raise NotImplementedError
      end

      protected

      # Rank by text match first, then by distance between 4-digit SA postal codes
      # (which are roughly geographic), as a cheap stand-in for geo distance.
      def rank(options, postal_code:, city:, query:)
        needle = [query, city].compact_blank.map(&:downcase)
        target = postal_code.to_s[/\d{4}/]&.to_i
        options.sort_by do |o|
          text = [o.name, o.address['street'], o.address['suburb'], o.address['city']].join(' ').downcase
          match = needle.empty? || needle.any? { |n| text.include?(n) } ? 0 : 1
          distance = target ? (o.address['postal_code'].to_i - target).abs : 0
          [match, distance, o.name]
        end
      end
    end
  end
end
