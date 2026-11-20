# EcloudMall: SA Payment Gateways & Logistics Partners (Paxi / Pargo)

**Status:** In Progress
**Target:** Spree 5.4 (EcloudMall fork)
**Depends on:** `ecloudmall-marketplace.md`, `6.0-fulfillment-and-delivery.md` (PickupPointProvider design)
**Author:** EcloudMall
**Last updated:** 2026-11-19

## Summary
Add the three payment options South African shoppers expect — **PayFast** (cards, Instant EFT, SnapScan,
Zapper, Mobicred…), **Ozow** (Instant EFT / PayShap) and **Yoco** (cards, Apple/Google Pay) — and build the
system side of a two-way partnership with pickup-point networks **Paxi** and **Pargo**: partner-branded pickup
delivery methods with a pickup-point picker, a seller referral programme run through partner counters, and
partner statements (parcel volumes, fees owed, referral earnings, investment terms) in the admin.
The commercial proposal lives in `docs/partnerships/paxi-pargo-partnership.md`.

## Key Decisions (do not deviate without discussion)
- **Gateways use the Spree 5.4 payment-session contract** (`session_required? = true`,
  `create_payment_session` / `complete_payment_session` / `parse_webhook_event`). No new checkout endpoints.
  The storefront creates a session, redirects the shopper to the provider, and the order is completed by
  either the signed provider notification (`POST /api/v3/webhooks/payments/:payment_method_id`) or a verified
  return — whichever arrives first — via `Spree::Payments::HandleWebhook`. Both paths are idempotent.
- **Never trust the browser.** A payment completes only after: PayFast — ITN signature + server-side
  `validate` postback + amount match; Ozow — SHA512 hash of notification/return fields + amount match;
  Yoco — Svix-style webhook signature (`webhook-id.timestamp.body`, HMAC-SHA256) with 3-minute tolerance, or
  a server-side checkout lookup on return. Amount mismatches fail the session.
- **Return URLs are allow-listed**: only origins in the store's `allowed_origins` (or the store URL) are
  accepted from the storefront, preventing open redirects.
- **Pickup points are not stored in the database** (per `6.0-fulfillment-and-delivery.md`). Providers return
  ephemeral `Spree::PickupPointOption` values; the selected point is frozen as `pickup_point_data` JSON on the
  fulfillment (shipment). Delivery methods name their provider in `pickup_point_provider`.
- Partner integrations are adapters behind `Spree::PickupPointProvider::Base`. Until a partner grants API
  access, `SampleDirectory` serves clearly-labelled sample points from YAML; `PartnerFeed` is a configurable
  JSON adapter to be pointed at the partner's endpoint once onboarded. We do not guess partner APIs.
- `Spree::Partner` holds the commercial terms (status, carrier/investor/referral roles, negotiated parcel
  cost, volume tiers, referral rates, investment) so statements are computed, not spreadsheeted.
- Seller referrals: an application with a partner `referral_code` gets the partner's reduced commission for
  the referral period; the partner earns a share of referred sellers' paid GMV for the same period.

## Design Details
**Gateways** (`spree/marketplace/app/models/spree/gateway/{payfast,ozow,yoco}.rb`, STI session classes in
`app/models/spree/payment_sessions/`). `external_data.redirect` returned to the storefront:
`{ method: 'POST'|'GET', url:, fields: {} }`. PayFast and Ozow are form POSTs; Yoco is a GET to the hosted
checkout returned by `POST https://payments.yoco.com/api/checkouts`. Capture is a no-op success (funds are
captured by the provider); refunds: Yoco via API, PayFast/Ozow are refunded in the provider dashboard
(gateway returns a clear failure message from `credit`).

**Partners** `spree_partners` (soft-deleted, store-scoped, prefix `prt_`): name, code (also the referral
code), status (`prospect → in_talks → pilot → active`, `paused`), roles (`carrier`, `investor`, `referral`),
`parcel_cost` (negotiated per-parcel cost), `volume_tiers` JSON, `referral_commission_rate`,
`referral_gmv_share_rate`, `referral_months`, `investment_amount`, `equity_percent`, `logistics_credit`,
contact + notes. Associations: `shipping_methods.partner_id`, `sellers.referred_by_partner_id`.

**Store API**
- `GET /api/v3/store/delivery_methods/:id/pickup_points?postal_code=&city=&q=`
- `PATCH /api/v3/store/carts/:cart_id/fulfillments/:id/pickup_point` `{ pickup_point_id }`
- Fulfillment payload adds `pickup_point` (snapshot) and `delivery_method.pickup_point_provider` flag.
- `POST /seller_applications` accepts `referral_code`.

**Admin** Marketplace → Partners: terms form and a monthly statement (parcels, delivery revenue, parcel
costs owed, margin, tier reached, referred sellers, referred GMV, referral share owed).

## Migration Path
1. `bin/rails spree_marketplace:install:migrations && bin/rails db:migrate`
2. `bin/rails ecloudmall:setup_store` adds the gateways (inactive until credentials are entered, except
   sandbox PayFast) and the Paxi / Pargo partner records + pickup delivery methods.

## Constraints on Current Work
- Use "delivery method", "fulfillment" and "pickup point" in new API code (not shipping/shipment).
- Do not persist third-party pickup points as records.
- Never mark a payment complete from browser-supplied parameters without signature/server verification.

## Open Questions
- Partner API specs and credentials (Paxi, Pargo) — obtained during partnership onboarding.
- Whether PayShap is exposed via Ozow or a bank partner; Mobicred/BNPL via PayFast.
- Cash-on-collection at partner counters (partner collects payment) — commercial/compliance review.

## References
- `docs/partnerships/paxi-pargo-partnership.md`
- PayFast developer docs (custom integration, ITN), Ozow merchant integration docs, Yoco Checkout API docs
