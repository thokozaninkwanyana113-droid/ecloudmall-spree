module Spree
  module PickupPointProvider
    # Generic JSON adapter for a partner's pickup-point endpoint, configured per partner code:
    #
    #   PARTNER_<CODE>_POINTS_URL   e.g. https://api.partner.example/pickup-points
    #   PARTNER_<CODE>_API_KEY      sent as `Authorization: Bearer <key>`
    #
    # Expects `GET <url>?postal_code=&city=&q=&limit=` returning an array (or `{ data: [] }`) of
    # objects with id, name, street, suburb, city, postal_code, province, hours, kind.
    # Adjust #map_point to the partner's real schema during onboarding.
    class PartnerFeed < Base
      def find_nearby(postal_code: nil, city: nil, query: nil, limit: 10)
        fetch(postal_code: postal_code, city: city, q: query, limit: limit).first(limit)
      end

      def find_by_external_id(external_id)
        id = external_id.to_s.delete_prefix("#{provider_code}-")
        fetch(id: id).find { |o| o.external_id == external_id.to_s }
      end

      private

      def fetch(params)
        url = ENV["PARTNER_#{provider_code.upcase}_POINTS_URL"]
        return [] if url.blank?

        uri = URI.parse(url)
        uri.query = URI.encode_www_form(params.compact_blank)
        response = Spree::Marketplace::HttpClient.new.get(uri.to_s, headers: auth_headers)
        return [] unless response.success?

        rows = response.json.is_a?(Hash) ? Array(response.json['data']) : Array(response.json)
        rows.map { |row| map_point(row) }
      rescue StandardError => e
        Rails.logger.error("[PickupPoints:#{provider_code}] #{e.message}")
        []
      end

      def auth_headers
        key = ENV["PARTNER_#{provider_code.upcase}_API_KEY"]
        key.present? ? { 'Authorization' => "Bearer #{key}" } : {}
      end

      def map_point(row)
        Spree::PickupPointOption.new(
          external_id: "#{provider_code}-#{row['id']}",
          name: row['name'],
          provider: provider_code,
          kind: row['kind'] || 'store',
          address: row.slice('street', 'suburb', 'city', 'postal_code', 'province').merge('country_code' => 'ZA'),
          opening_hours: row['hours'],
          metadata: row.except('id', 'name', 'street', 'suburb', 'city', 'postal_code', 'province', 'hours', 'kind')
        )
      end
    end
  end
end
