#!/usr/bin/env bash
# Sets up EcloudMall for local development: the backend in apps/backend (Spree + marketplace engine)
# and the Next.js storefront, with demo sellers.
#
#   ./scripts/setup-ecloudmall.sh
#
# Requirements: Ruby 3.3+, Node 22+, pnpm, PostgreSQL and Redis running locally.
# Env overrides: DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_HOST (or DATABASE_URL)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/apps/backend"

echo "▸ Installing gems"
bundle install

echo "▸ Preparing database"
bin/rails db:prepare

echo "▸ Building admin CSS"
bin/rails spree:admin:tailwindcss:build

echo "▸ Configuring EcloudMall (ZAR, 15% VAT, SA delivery & payments) and demo sellers"
bin/rails ecloudmall:setup

PK=$(bin/rails runner 'print Spree::ApiKey.publishable.first&.token' 2>/dev/null | tail -1)

cd "$ROOT"
echo "▸ Installing storefront dependencies"
pnpm install
pnpm --filter @spree/sdk-core build
pnpm --filter @spree/sdk build

if [ ! -f apps/storefront/.env.local ]; then
  printf "SPREE_API_URL=http://localhost:3000\nSPREE_PUBLISHABLE_KEY=%s\nNEXT_PUBLIC_SITE_URL=http://localhost:3001\n" "$PK" > apps/storefront/.env.local
fi

cat <<MSG

✔ EcloudMall is ready.

  Backend + admin:  cd apps/backend && bin/dev   (web + worker) → http://localhost:3000/admin  (spree@example.com / spree123)
  Storefront:       pnpm --filter @ecloudmall/storefront dev     → http://localhost:3001
MSG
