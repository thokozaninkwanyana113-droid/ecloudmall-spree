module Spree
  # Ephemeral third-party pickup point returned by a PickupPointProvider — never persisted.
  # Mirrors the value object in docs/plans/6.0-fulfillment-and-delivery.md.
  PickupPointOption = Struct.new(
    :external_id, :name, :provider, :address, :opening_hours, :kind, :metadata,
    keyword_init: true
  ) do
    def as_json(*)
      to_h.deep_stringify_keys
    end
  end
end
