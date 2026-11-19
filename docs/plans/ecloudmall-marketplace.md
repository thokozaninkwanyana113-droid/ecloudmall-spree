# EcloudMall Marketplace (multi-seller, South Africa)

**Status:** In Progress
**Target:** Spree 5.4 (EcloudMall fork)
**Depends on:** `5.4-search-provider.md` (product filtering goes through the Database search provider)
**Author:** EcloudMall
**Last updated:** 2026-11-19

## Summary
EcloudMall is a marketplace for South African SMMEs (small, medium and micro enterprises). This plan adds a
`spree_marketplace` engine (`spree/marketplace`) that introduces **sellers** — independent businesses who apply to
sell, are approved by staff, and whose products are listed in a shared catalogue — plus a Next.js storefront
(`apps/storefront`) built on `@spree/sdk`.

## Key Decisions (do not deviate without discussion)
- The model is `Spree::Seller`, **not** `Spree::Vendor`. Spree core/admin contain `defined?(Spree::Vendor)` hooks
  reserved for Spree Enterprise's multi-vendor edition; defining that constant breaks the admin dashboard.
- Marketplace code lives in its own engine and extends core via concerns included in `to_prepare`
  (`Spree::Marketplace::ProductSeller`, `LineItemSeller`, `StoreSellers`) — no edits to `spree/core`.
- Single-order, managed-marketplace model: orders are not split per seller. Fulfilment runs through an
  EcloudMall hub stock location; each `LineItem` snapshots `seller_id` at creation so commission/payouts are
  stable even if a product later moves to another seller.
- Payouts are computed only from fully **paid** orders (`payment_state = 'paid'`), net of the seller's
  `commission_rate` (default 7.5%).
- Store API exposes only `approved` sellers; products of non-approved sellers are filtered out of
  `GET /api/v3/store/products` (house products with no seller remain visible).
- Public applications (`POST /api/v3/store/seller_applications`) always create `pending` sellers; status,
  commission, featured and verified flags are never accepted from the storefront.
- SA specifics are data, not code paths: provinces use ISO 3166-2:ZA codes (`GP`, `KZN`, …), B-BBEE level 1–8,
  CIPC registration and VAT numbers are optional strings, ZAR + 15% VAT included in price.

## Design Details
**Model** `spree_sellers` (soft-deleted, store-scoped, friendly_id slug scoped to store, prefix `sel_`):
profile (name, tagline, description, story), contact, location (province/city/township), business profile
(business_type, size_band, registration_number, vat_number, bbbee_level, ownership booleans), fulfilment
(ships_nationwide, offers_collection, dispatch_days), marketplace (status, commission_rate, featured, verified,
approved_at/rejected_at, admin_notes), `logo`/`banner` attachments. State machine on `status`:
`pending → approved ⇄ suspended`, `pending → rejected → approved`.

**Store API**
- `GET /api/v3/store/sellers` — Ransack filters e.g. `q[province_eq]=GP`, `q[women_owned_eq]=true`
- `GET /api/v3/store/sellers/:slug_or_id`
- `POST /api/v3/store/seller_applications`
- Products: serializer swapped to `MarketplaceProductSerializer` (adds `seller_id`, compact `seller`);
  filters `q[seller_slug_eq]`, `q[seller_province_eq]`, `q[seller_black_owned_eq]`, etc.

**Admin** Marketplace → Sellers (index table, edit form, approve/reject/suspend, sales & payout card),
"Sold by" select on the product form, pending-count badge in the sidebar.

**Setup** `bin/rails ecloudmall:setup` configures the store (ZAR market, SA zone, VAT 15% inclusive, courier /
Paxi-Pargo pickup / express delivery, EFT and pay-on-delivery with manual capture) and loads demo sellers.

## Migration Path
1. `bin/rails spree_marketplace:install:migrations && bin/rails db:migrate`
2. `bin/rails ecloudmall:setup_store` (optional `ecloudmall:load_demo`)

## Constraints on Current Work
- Do not introduce a `Spree::Vendor` constant anywhere.
- New seller-facing fields must be added to the serializer explicitly — never expose email, commission,
  registration/VAT numbers or admin notes through the Store API.

## Open Questions
- Seller self-service portal (sellers managing their own products/orders) — likely an admin role scoped by seller.
- Online payments: PayFast / Ozow / Yoco gateway integrations (currently EFT + pay on delivery).
- Automated payout runs and seller statements; per-seller fulfilment (drop-ship) instead of the hub model.
- Courier integrations (The Courier Guy, Pargo/Paxi APIs) for live rates and tracking.

## References
- `spree/marketplace/README.md`, `apps/storefront/README.md`
