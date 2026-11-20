require 'yaml'

module Spree
  module PickupPointProvider
    # Serves clearly-labelled SAMPLE pickup points from config/pickup_points/sample.yml so the
    # checkout flow can be demonstrated before a partner grants API access. Replace with
    # PartnerFeed (or a dedicated adapter) once the partner integration is live.
    class SampleDirectory < Base
      DATA_FILE = Spree::Marketplace::Engine.root.join('config/pickup_points/sample.yml')

      def self.all_points
        @all_points ||= YAML.safe_load_file(DATA_FILE)
      end

      def find_nearby(postal_code: nil, city: nil, query: nil, limit: 10)
        rank(options, postal_code: postal_code, city: city, query: query).first(limit)
      end

      def find_by_external_id(external_id)
        options.find { |o| o.external_id == external_id.to_s }
      end

      private

      def options
        self.class.all_points.fetch(provider_code, []).map do |p|
          Spree::PickupPointOption.new(
            external_id: "#{provider_code}-#{p['id']}",
            name: p['name'],
            provider: provider_code,
            kind: p['kind'] || 'store',
            address: p.slice('street', 'suburb', 'city', 'postal_code', 'province').merge('country_code' => 'ZA'),
            opening_hours: p['hours'],
            metadata: { 'sample' => true }
          )
        end
      end
    end
  end
end
