# spree_marketplace

Multi-seller marketplace engine for **EcloudMall**, the marketplace for South African SMMEs.

- `Spree::Seller` — SMME sellers with SA business profile (province, CIPC, VAT, B-BBEE level, Black/women/youth/
  disability/township ownership), approval workflow and commission rate
- Store API: `GET /api/v3/store/sellers`, `GET /api/v3/store/sellers/:id`, `POST /api/v3/store/seller_applications`
- Products carry a `seller` (embedded in Store API product payloads) and can be filtered by seller attributes
- Line items snapshot the seller for commission and payout reporting (`Spree::Seller#sales_summary`)
- Admin: Sellers section (approve / reject / suspend, sales & payouts), "Sold by" on the product form
- `bin/rails ecloudmall:setup` — configures ZAR, 15% VAT, SA delivery options and payments, and loads 10 demo sellers

- **Payments:** PayFast, Ozow and Yoco hosted gateways (`Spree::Gateway::{Payfast,Ozow,Yoco}`) on Spree's
  payment-session API, with signature-verified webhooks and return verification
- **Logistics partners:** `Spree::Partner` (Paxi, Pargo…), pickup-point delivery methods with a pickup-point
  picker (`PickupPointProvider`), seller referral codes, and monthly partner statements in the admin

- **Funds flow:** append-only ledger of what EcloudMall owes each seller and partner (sales, commission,
  refund clawback, partner parcel costs and referral share), payout runs with a bank bulk-payment CSV,
  encrypted bank accounts, and provider refunds (PayFast Refunds API, Yoco; Ozow/EFT recorded) in Admin → Finance

See `docs/plans/ecloudmall-marketplace.md`, `docs/plans/ecloudmall-payments-and-logistics-partners.md` and
`docs/plans/ecloudmall-funds-flow.md`.

## Money: how funds move

| Movement | How it happens | Where you see it |
|---|---|---|
| Customer → EcloudMall | PayFast / Ozow / Yoco (verified notification), manual EFT or pay on delivery (captured in admin) | Order payments |
| EcloudMall → seller | Order paid → `sale` − `commission` accrue; available after the returns hold (`ECLOUDMALL_PAYOUT_HOLD_DAYS`, default 7) → payout run | Finance, seller page |
| Customer refund | Admin refund → provider refund API (PayFast live / Yoco) or recorded for EFT/Ozow → seller clawback pro rata, commission returned | Order, Finance |
| EcloudMall → partner | Partner page → *Close month* accrues parcel costs (net of logistics credit) + referral share → payout run | Partner page, Finance |
| Payout run | Finance → *New payout run* → Approve → Download bank CSV → upload to bank → *Mark all paid* (bounced transfers → *Mark failed* re-credits the payee) | Finance → Payout runs |

Schedule these (cron, Sidekiq-Cron, or your platform's scheduler):

```bash
bin/rails ecloudmall:ledger:sync          # nightly; idempotent safety net for missed events
bin/rails ecloudmall:close_partner_month  # 1st of each month
```

Events keep the ledger current in real time (`payment.completed`, `order.completed`, `refund.created`),
so run the background worker (`bundle exec sidekiq`).

## Payment gateway configuration

Set these before `bin/rails ecloudmall:setup_store`, or edit them later in Admin → Settings → Payment methods.

| Gateway | Environment variables | Notes |
|---|---|---|
| PayFast | `PAYFAST_MERCHANT_ID`, `PAYFAST_MERCHANT_KEY`, `PAYFAST_PASSPHRASE`, `PAYFAST_TEST_MODE`, `PAYFAST_VALIDATE_ITN` | Defaults to PayFast's shared sandbox merchant (no passphrase). Leave ITN validation on in production. |
| Ozow | `OZOW_SITE_CODE`, `OZOW_PRIVATE_KEY`, `OZOW_API_KEY`, `OZOW_TEST_MODE` | Activated when `OZOW_SITE_CODE` is set |
| Yoco | `YOCO_SECRET_KEY`, `YOCO_WEBHOOK_SECRET` | Register `…/api/v3/webhooks/payments/<payment method id>` as a Yoco webhook to get the secret |

- Provider notifications are sent to `<store URL or notify_base_url>/api/v3/webhooks/payments/<payment method id>`.
  The URL must be publicly reachable; use a tunnel in development.
- Webhooks are processed by a background job, so run a worker (`bundle exec sidekiq`, or `bin/dev`).
- Storefront return URLs must be on one of the store's allowed origins (`ECLOUDMALL_STOREFRONT_URL`, default
  `http://localhost:3001`, is added by setup).

## Pickup-point partners

`ecloudmall:setup_store` creates Paxi and Pargo as **prospect** partners with *proposed* terms, plus a
"Collect at a … point" delivery method for each. Until a partner feed is configured, those methods use
`SampleDirectory`: clearly-labelled demo points from `config/pickup_points/sample.yml`. Once a partner
provides API access, set `PARTNER_<CODE>_POINTS_URL` and `PARTNER_<CODE>_API_KEY` and re-run setup to
switch that delivery method to `PartnerFeed`.

## Tests

```bash
cd spree/marketplace
bundle install
bundle exec rake test_app
bundle exec rspec
```
