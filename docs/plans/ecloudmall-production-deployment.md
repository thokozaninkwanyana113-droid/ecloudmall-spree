# EcloudMall: Production Deployment (Render)

**Status:** In Progress
**Target:** Spree 5.4 (EcloudMall fork)
**Depends on:** `spree-starter-and-create-spree-app.md`, `ecloudmall-funds-flow.md`, `ecloudmall-payments-and-logistics-partners.md`
**Author:** EcloudMall
**Last updated:** 2026-11-27

## Summary
EcloudMall runs on Render (Frankfurt, the closest region to South Africa) from one `render.yaml` Blueprint:
a Dockerised Rails API/admin, a Sidekiq worker, two cron jobs (ledger sync, partner month close), the
Next.js storefront, Postgres 16 and a Key Value (Redis) instance. The backend Rails app is committed at
`apps/backend` so production builds exactly what CI tests.

## Key Decisions (do not deviate without discussion)
- **`apps/backend` is the deployable Rails app.** It is the spree-starter app wired to the monorepo engines via
  relative paths (`../../spree`), so `Gemfile.lock` is portable. `server/` remains a git-ignored local sandbox.
- **Docker build from the repo root** (`apps/backend/Dockerfile`, `.dockerignore` at root) so engine sources are
  in the image. Ruby 3.3.6 (matches what is tested locally and in E2E).
- **Fail closed in production.** `config/initializers/ecloudmall_production_checks.rb` refuses to boot without
  `SECRET_KEY_BASE`, the three Active Record encryption keys, `DATABASE_URL` and `REDIS_URL`. Bank account
  numbers are always encrypted in production.
- **No sandbox money in production.** `ecloudmall:bootstrap` only activates PayFast/Ozow/Yoco when real credentials
  are present; the public PayFast sandbox merchant is never used in production. Demo sellers are not loaded
  unless `ECLOUDMALL_DEMO_DATA=true`. Bootstrap aborts while the default `spree@example.com` / `spree123` admin works.
- **First boot only.** The web container's entrypoint runs `db:prepare` then `ecloudmall:bootstrap_once`
  (skipped once the store is configured; `ECLOUDMALL_FORCE_BOOTSTRAP=true` re-applies ENV settings). Workers and
  cron jobs never migrate or bootstrap.
- **Storefront → API over Render's private network** (`SPREE_API_URL` from the API's `hostport`); Rails runs with
  `assume_ssl` so internal HTTP isn't redirected. Browsers load images from the API's public host (`RAILS_HOST`).
- **Uploads need object storage.** Render disks are ephemeral; set Cloudflare R2 (or AWS S3) variables before
  sellers upload logos/photos.

## Design Details
| Resource | Type | Plan | Notes |
|---|---|---|---|
| ecloudmall-api | web (docker) | starter | `/up` health check; migrates + bootstraps on boot |
| ecloudmall-worker | worker (docker) | starter | Sidekiq: payment webhooks, ledger events, emails |
| ecloudmall-ledger-sync | cron | starter | `0 1 * * *` — `ecloudmall:ledger:sync` |
| ecloudmall-close-partner-month | cron | starter | `15 2 1 * *` — `ecloudmall:close_partner_month` |
| ecloudmall-storefront | web (node 22) | starter | pnpm workspace build of SDK + storefront |
| ecloudmall-redis | keyvalue | starter | `noeviction` (Sidekiq) |
| ecloudmall-db | postgres 16 | basic-1gb | daily backups (Render) |

Shared settings live in the `ecloudmall-backend` env group (generated secrets, admin login, URLs, payment, SMTP,
object storage).

## Migration Path
1. Apply the Blueprint (fill admin email/password; payment/SMTP/R2 can be filled later).
2. First API deploy migrates, seeds and bootstraps; copy the printed publishable key into the storefront's
   `SPREE_PUBLISHABLE_KEY` and redeploy the storefront.
3. Add live PayFast credentials (and Ozow/Yoco) → set `ECLOUDMALL_FORCE_BOOTSTRAP=true` for one deploy (or run
   `bin/rails ecloudmall:bootstrap` from the Render shell). Register the webhook URLs with each provider.
4. Add custom domains (e.g. `api.` and `www.`), then update `ECLOUDMALL_STORE_URL`, `RAILS_HOST`,
   `ECLOUDMALL_STOREFRONT_URL` and `NEXT_PUBLIC_SITE_URL`.

## Constraints on Current Work
- Never rotate `ACTIVE_RECORD_ENCRYPTION_*` keys in place — stored bank details become unreadable.
- Keep `apps/backend` Gemfile paths relative; never commit `.env` files or keys.
- Don't run demo data or sandbox gateways in production.

## Open Questions
- Data residency: Render has no South African region; revisit AWS `af-south-1` if POPIA counsel requires in-country hosting.
- Error monitoring (`SENTRY_DSN`) and uptime alerts.

## References
- `render.yaml`, `apps/backend/Dockerfile`, `apps/backend/bin/docker-entrypoint`, `spree/marketplace/lib/tasks/ecloudmall.rake`
