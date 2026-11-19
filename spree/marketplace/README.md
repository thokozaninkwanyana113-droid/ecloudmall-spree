# spree_marketplace

Multi-seller marketplace engine for **EcloudMall**, the marketplace for South African SMMEs.

- `Spree::Seller` — SMME sellers with SA business profile (province, CIPC, VAT, B-BBEE level, Black/women/youth/
  disability/township ownership), approval workflow and commission rate
- Store API: `GET /api/v3/store/sellers`, `GET /api/v3/store/sellers/:id`, `POST /api/v3/store/seller_applications`
- Products carry a `seller` (embedded in Store API product payloads) and can be filtered by seller attributes
- Line items snapshot the seller for commission and payout reporting (`Spree::Seller#sales_summary`)
- Admin: Sellers section (approve / reject / suspend, sales & payouts), "Sold by" on the product form
- `bin/rails ecloudmall:setup` — configures ZAR, 15% VAT, SA delivery options and payments, and loads 10 demo sellers

See `docs/plans/ecloudmall-marketplace.md` for design decisions.

## Tests

```bash
cd spree/marketplace
bundle install
bundle exec rake test_app
bundle exec rspec
```
