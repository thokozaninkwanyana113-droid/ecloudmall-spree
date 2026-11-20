# EcloudMall: Funds Flow, Ledger & Payouts

**Status:** In Progress
**Target:** Spree 5.4 (EcloudMall fork)
**Depends on:** `ecloudmall-marketplace.md`, `ecloudmall-payments-and-logistics-partners.md`
**Author:** EcloudMall
**Last updated:** 2026-11-20

## Summary
Money moves between five parties: **customers**, **EcloudMall** (the merchant of record that collects all
payments), **sellers**, **logistics partners** (Paxi, Pargo) and **payment providers** (PayFast, Ozow, Yoco).
This plan adds an append-only **ledger** that records every amount owed to or by a seller or partner the moment
it happens, **payout runs** that pay out available balances by bank batch file, **bank accounts** for payees,
and **automatic clawback** when customers are refunded, so every rand can be traced from the customer's
payment to the seller's bank account.

## Key Decisions (do not deviate without discussion)
- **EcloudMall is merchant of record.** All customer money lands in EcloudMall's provider/bank accounts. Sellers
  and partners are paid out from there. No split payments at the provider (none of the three supports
  marketplace splits for our case without extra onboarding).
- **Append-only ledger, idempotent by key.** `Spree::LedgerEntry` rows are never edited or deleted; corrections
  are new entries. Each entry has a unique `idempotency_key` (e.g. `sale:li_123`, `refund:rf_9:li_123`) so the
  same event can be recorded repeatedly (event retries, nightly sync) without double counting.
- **Positive amount = EcloudMall owes the payee.** A payee's balance is the sum of their entries.
- **Accrual triggers**
  - Order **paid** (`payment_state = 'paid'`) → per seller line item: `sale` (+ line total) and `commission`
    (− effective commission rate, which honours partner referral discounts).
  - **Refund** → allocated pro rata across the order's line items by value; per seller line item: `refund`
    (− allocated amount) and `commission_reversal` (+ the commission on it). Delivery share stays with EcloudMall.
  - **Partner month close** (`Partner#close_month!`) → `parcel_costs` (+) net of in-kind credit, and
    `referral_share` (+), from the partner statement. Idempotent per partner and month.
  - **Payout paid** → `payout` (− amount). **Payout failed** after being marked paid → `payout_reversal` (+).
- **Holds.** Seller sale entries become available `hold_days` (default 7) after the order is paid, to cover
  returns and chargebacks. Partner entries are available immediately after month close. A negative balance
  (refund after payout) is netted from future payouts.
- **Triggers are belt and braces.** `payment.completed` and `refund.created` event subscribers sync an order's
  entries asynchronously, and creating a payout run first re-syncs recent orders, so a missed event never
  causes an underpayment.
- **Payout runs** (`Spree::PayoutBatch` → `Spree::Payout`): draft (amounts computed from available balance ≥
  minimum, payee must have a verified bank account) → approved → exported (bank bulk-payment CSV) → paid. A
  single payout can be marked failed (bounced). Bank details are snapshotted onto each payout.
- **Bank account numbers are encrypted** with Active Record encryption when the app has keys configured
  (same pattern as `Spree::WebhookEndpoint`); only the last 4 digits are shown in the admin.
- **Customer refunds go back through the original provider where it has a refund API** — PayFast (Refunds API,
  signed per its official SDK; live only), Yoco (checkout refund). Ozow and manual EFT refunds are paid by bank
  transfer and recorded in Spree. Either way the ledger clawback is the same.
- **Provider fees** reported by the provider (e.g. PayFast `amount_fee`) are stored on the payment session for
  reconciliation; they are an EcloudMall cost and never charged to sellers.

## Design Details
- `spree_ledger_entries`: store, payee (polymorphic Seller/Partner), kind, amount (signed), currency,
  available_at, order, source (polymorphic: LineItem, Refund, Payout, Partner), description, idempotency_key
  (unique), metadata. Scopes: `available`, `pending`; `Payee#balance`, `available_balance`, `pending_balance`.
- `spree_bank_accounts`: owner (polymorphic Seller/Partner), account_holder, bank_name, branch_code,
  account_number (encrypted), account_type, verified_at.
- `spree_payout_batches`: store, number, status, currency, period_end, approved_at, exported_at, paid_at, totals.
- `spree_payouts`: batch, payee (polymorphic), amount, currency, status (pending/paid/failed/canceled),
  reference, bank snapshot (holder, bank, branch, account last4 + encrypted number, type), paid_at, failure_reason.
- `Spree::Marketplace::Ledger` service: `sync_order!(order)`, `record_payout!`, `close_partner_month!`.
- Admin → **Finance**: balances (sellers + partners: available, pending, total), payout runs (new → review →
  approve → download CSV → mark paid / mark one failed), bank account form on seller and partner pages,
  ledger list on seller page, "Close month" on partner page.
- Rake: `ecloudmall:ledger:sync` (re-sync orders paid or refunded in the last N days).

## Migration Path
1. `bin/rails spree_marketplace:install:migrations && bin/rails db:migrate`
2. `bin/rails ecloudmall:ledger:sync DAYS=365` to backfill entries for existing paid orders.

## Constraints on Current Work
- Never compute a payee's balance from orders directly in new code — read the ledger.
- Never update or delete a `LedgerEntry`; write a correcting entry.
- Never pay a payee without a verified bank account snapshot on the payout.

## Open Questions
- Seller self-service view of balances/payout history (needs a seller portal).
- VAT invoices for commission (EcloudMall → VAT-registered sellers) and PayFast/Ozow settlement-report import
  for automated bank reconciliation.
- Chargebacks/disputes from providers (currently recorded as manual refunds).

## References
- PayFast Refunds API usage: official `payfast-php-sdk` (`Services/Refunds.php`, `Request.php`, `Auth::generateApiSignature`)
