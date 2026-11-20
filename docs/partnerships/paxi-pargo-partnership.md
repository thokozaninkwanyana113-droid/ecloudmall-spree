# EcloudMall × Paxi / Pargo — Partnership & Investment Proposal

> **Status:** Draft for discussion · **Prepared by:** EcloudMall · **Last updated:** 2026-11-19
>
> All figures below are **EcloudMall's proposals and planning assumptions**, not agreed terms and not
> statements about Paxi's or Pargo's current pricing, volumes or strategy. Verify partner facts during
> discovery calls before using this externally.

## 1. The one-line pitch

**EcloudMall brings thousands of South African small businesses and their customers to your counters;
you bring the trusted, affordable, nationwide pickup network those businesses can't reach on their own.**
Both sides grow parcel volume, footfall and revenue, and the partnership can deepen into investment.

## 2. Why this partnership makes sense

| | What EcloudMall brings | What the pickup partner brings |
|---|---|---|
| **Volume** | Aggregated parcel demand from many SMME sellers, routed to the partner by default for pickup orders | Nationwide counter network, incl. townships and rural towns couriers find expensive to serve |
| **Customers** | Shoppers who choose pickup because it's cheaper — every collection is a visit to the partner's host store | Trusted, familiar brand that makes first-time online shoppers comfortable buying from small sellers |
| **New shippers** | SMME sellers who need affordable first-mile drop-off and returns | Counter staff who can sign up local businesses with a referral code — a new B2B channel for the partner |
| **Data** | Aggregated, POPIA-compliant demand insights by area/category (no personal data without consent) | Point availability, capacity and tracking events |
| **Capital** | Equity upside in a fast-growing SMME marketplace | Optional investment: cash, or *in-kind* as prepaid logistics credit |

**For the partner:** incremental parcels at a guaranteed default slot in checkout; footfall into host
stores; a seller acquisition channel; a stake in SMME e-commerce growth.
**For EcloudMall:** lower delivery cost (cheaper prices for shoppers), reach in every province, trust,
and capital or credit that extends runway without heavy dilution.
**For SMMEs and shoppers:** R59 pickup instead of R99+ courier, collection at convenient hours, and a
reduced commission for sellers referred through the partner.

## 3. What is already built in EcloudMall (ready for a pilot)

The platform side of this proposal exists today (see `docs/plans/ecloudmall-payments-and-logistics-partners.md`):

- **Partner-branded pickup delivery** — "Collect at a Paxi point" / "Collect at a Pargo point" with a
  pickup-point picker at checkout. The chosen point is frozen onto the order and shown to the shopper.
- **Integration adapters** — `PickupPointProvider` interface with a `PartnerFeed` adapter that only needs
  the partner's pickup-point API endpoint and key. Demo mode uses clearly-labelled *sample* points.
- **Partner terms & statements** (Admin → Partners) — negotiated per-parcel cost with monthly volume
  tiers, seller referral rates, investment / equity / logistics-credit fields. The monthly statement
  shows parcels, delivery fees collected, costs owed, margin, next tier, referred sellers, referred GMV,
  referral share and amount payable. Computed from real orders, so both sides reconcile against one number.
- **Seller referral codes** — sellers enter the partner's code (e.g. `PAXI`) when applying. They get the
  reduced commission for the referral period, and the partner earns a share of their paid GMV.
- **Online payments** — PayFast, Ozow and Yoco, so pickup orders are prepaid and counter staff never handle cash.

## 4. Proposed commercial model

### 4.1 Carrier terms (per parcel, ZAR incl. VAT)

| Monthly parcels via partner | Proposed cost to EcloudMall | Customer price | EcloudMall margin |
|---|---|---|---|
| 0 – 999 | R45 | R59 | R14 |
| 1,000 – 4,999 | R40 | R59 | R19 |
| 5,000+ | R36 | R59 | R23 |

The best tier reached in a month applies to all parcels that month (configured as `volume_tiers`).
EcloudMall may reinvest margin in "free pickup over RX" campaigns that grow volume for the partner.

**Illustrative monthly scenarios** (assumption: all pickup parcels at the tier rate above)

| Parcels / month | Paid to partner | EcloudMall delivery margin |
|---|---|---|
| 1,000 | R40,000 | R19,000 |
| 5,000 | R180,000 | R115,000 |
| 20,000 | R720,000 | R460,000 |

### 4.2 Seller referral programme

- Partner counter staff hand local businesses a referral code (QR flyer at the counter).
- **Seller benefit:** 5% commission instead of the standard 7.5% for the first 6 months.
- **Partner benefit:** 1% of referred sellers' *paid* GMV for the same 6 months, plus their outbound parcels.
- Illustration: 200 referred sellers × R8,000 paid GMV/month = R1.6m GMV → **R16,000/month to the partner**,
  R200/month saved per seller, and the sellers' parcels flow through the partner network.

### 4.3 Investment options (choose one, or none)

| Option | Mechanism | Why it works for both |
|---|---|---|
| **A. Logistics credit for equity** *(preferred)* | Partner provides prepaid parcel credit (e.g. R1m ≈ 25,000 parcels at R40). It is drawn down automatically on statements (`logistics_credit`) in exchange for equity | Partner invests capacity rather than cash; credit converts into volume on its own network |
| **B. Convertible note / SAFE** | Cash investment that converts at the next priced round, with a discount and cap | Simple, fast and defers valuation |
| **C. Strategic equity** | Priced equity with an observer seat and preferred-partner rights | Deepest alignment, usually after a successful pilot |

Equity under option A = credit ÷ agreed post-money valuation (e.g. R1m at R20m post-money = 5%).
**Illustrative only** — the valuation is agreed in negotiation, with independent advice.

Investor rights we're open to: board observer, information rights, right of first refusal on logistics
exclusivity in defined regions, and pro-rata in future rounds.

## 5. 90-day pilot

| | |
|---|---|
| **Scope** | Gauteng + Western Cape; pickup option live at checkout; seller referral codes at 20–50 partner counters |
| **Integration** | Week 1–2: API keys, point directory feed, tracking webhooks · Week 3: staging end-to-end · Week 4: launch |
| **Exclusivity** | None during the pilot (both networks can be offered); preferred placement for the better-performing partner afterwards |
| **KPIs** | Pickup share of orders · parcels/month · on-time ready-for-collection % · uncollected/return rate · sellers referred & activated · referred GMV · NPS of collectors |
| **Success criteria (proposed)** | ≥ 30% of eligible orders choose pickup · ≥ 95% ready-for-collection on time · ≥ 100 referred sellers activated |
| **Review** | Day 45 check-in; day 90 decision on full rollout, volume commitment and investment track |

## 6. How we approach them

1. **Discovery (week 0–2).** Map the decision-makers: partnerships / e-commerce lead, head of B2B or
   SME shipping, and corporate development for investment. Verify current pickup pricing, API
   availability, coverage and integration requirements. Prefer warm introductions through SMME
   ecosystem networks (incubators, accelerators, enterprise and supplier development programmes).
2. **Run both conversations in parallel and non-exclusively.** Competition improves terms, and the
   system already supports both partners side by side.
3. **First meeting: show, don't tell.** Live demo of pickup checkout, the partner statement and the
   referral flow, followed by this one-pager. Ask for: API sandbox access, a pilot rate card, and
   20–50 pilot counters for referral flyers.
4. **Second meeting: commercials.** Tiered rate card, referral share, data-sharing terms and pilot
   KPIs. Introduce the investment options only once the pilot is agreed.
5. **Pilot agreement.** A short pilot MOU covering rates, SLAs, data processing (POPIA operator
   agreement), branding and an exit clause.
6. **Day 90.** Volume commitment, a preferred-partner tier, and an investment term sheet if both sides want it.

**Likely objections → responses**
- *"You're too small."* → The pilot is low-risk, and volume is visible in real time. The tiered rate card
  rewards growth rather than requiring an up-front commitment.
- *"Integration effort."* → The adapter already exists on our side. We need an endpoint, a key and
  tracking webhooks.
- *"Uncollected parcels."* → Prepaid orders only (PayFast/Ozow/Yoco), SMS reminders, and a shared
  return-to-seller process with a fee schedule.
- *"Brand risk from small sellers."* → Every seller is vetted and approved by staff (CIPC/VAT
  captured), and products from suspended sellers are hidden automatically.

## 7. Data, privacy and compliance

- Shopper personal data is shared only as needed to deliver the parcel (name, mobile, order reference),
  under a POPIA operator agreement.
- Partner insights are aggregated (area/category volumes), never individual-level profiles.
- Sample pickup points used in demos are clearly labelled and will be replaced by the partner's live directory.

## 8. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Partner capacity at peak (Black Friday, December) | Volume forecasts shared monthly; fallback to courier at checkout |
| Pricing changes | Rate card fixed for the pilot and indexed annually thereafter |
| Over-dependence on one network | Multi-partner architecture; non-exclusive pilot |
| Referral abuse | Codes only work for live partners; referral period capped; share paid on *paid* GMV only |

## 9. Non-binding term-sheet outline

- Parties, pilot term (90 days) and rollout option
- Rate card + volume tiers; invoicing monthly against the EcloudMall partner statement
- SLAs: ready-for-collection time, collection window, returns process
- Referral programme: seller rate, partner share, period, attribution rules
- Data processing (POPIA), branding/co-marketing, confidentiality
- Investment track (optional): instrument, amount or credit, valuation mechanics, information rights
- Exit/termination and dispute resolution

## 10. Next steps checklist

- [ ] Verify each partner's current public pricing, coverage and API documentation
- [ ] Identify contacts and secure warm introductions
- [ ] Prepare the live demo environment (staging with the partner's sandbox, if available)
- [ ] Update partner records (Admin → Partners) from *prospect* to *in_talks*, then *pilot*, as agreed
- [ ] Replace sample pickup points with the partner feed (`PARTNER_<CODE>_POINTS_URL` / `_API_KEY`)
- [ ] Legal review of MOU and POPIA operator agreement; independent advice on any investment
