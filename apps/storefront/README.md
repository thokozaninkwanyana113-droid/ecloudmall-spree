# EcloudMall storefront

Next.js 16 (App Router, React 19, Tailwind 4) storefront for EcloudMall, built on `@spree/sdk` and the
`spree_marketplace` Store API endpoints.

| Route | What it does |
|---|---|
| `/` | Hero, categories, trending, shop-by-province, seller spotlight, load-shedding kit, featured makers |
| `/shop` | Catalogue with search, category, province and impact (Black-/women-/youth-owned, township) filters, sorting, pagination |
| `/products/[slug]` | Product page with seller card, delivery ETA, impact badges, more from this seller |
| `/sellers`, `/sellers/[slug]` | Seller directory and branded seller storefronts |
| `/cart`, `/checkout`, `/orders/[id]` | Cart with free-delivery meter and promo codes, 3-step checkout (address → delivery → payment), confirmation with EFT instructions |
| `/sell` | Seller pitch, fee calculator and application form |
| `/account` | Register / log in, order history |

All Spree calls happen server-side (server components and server actions); the guest cart token and customer
JWT live in httpOnly cookies. Products without photos get generated Ndebele-inspired artwork.

```bash
cp .env.example .env.local   # set SPREE_PUBLISHABLE_KEY
pnpm dev                     # http://localhost:3001
pnpm test && pnpm typecheck && pnpm build
```
