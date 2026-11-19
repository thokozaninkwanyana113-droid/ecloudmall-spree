#!/usr/bin/env bash
# Sets up a local EcloudMall backend (Spree + marketplace engine) and storefront.
#
#   ./scripts/setup-ecloudmall.sh
#
# Requirements: Ruby 3.3+, Node 22+, pnpm, PostgreSQL and Redis running locally.
# Env overrides: DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_HOST
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STARTER_TAG="${STARTER_TAG:-v5.4.0.rc5}" # spree-starter release matching this repo's Spree version
cd "$ROOT"

if [ ! -d server ]; then
  echo "▸ Cloning spree-starter ${STARTER_TAG} into server/"
  git clone -q --depth 1 --branch "$STARTER_TAG" https://github.com/spree/spree-starter.git server
  rm -rf server/.git server/.gitignore
fi

cd server
echo "SPREE_PATH=.." > .env
ruby -e 'print RUBY_VERSION' > .ruby-version

# Use the local marketplace engine; drop optional gems that don't match this Spree version.
grep -q spree_marketplace Gemfile || sed -i.bak "/gem 'spree_admin', path:/a\\
  gem 'spree_marketplace', path: \"#{spree_path}/spree/marketplace\"
" Gemfile
sed -i.bak "/^gem 'spree_stripe'/d; /^gem 'spree_i18n'$/d" Gemfile
grep -q 'password:' config/database.yml || sed -i.bak 's/^\(  username: .*\)$/\1\n  password: <%= ENV.fetch("DATABASE_PASSWORD") { "" } %>/' config/database.yml
rm -f Gemfile.bak config/database.yml.bak

echo "▸ Installing gems"
bundle install

echo "▸ Preparing database"
bin/rails db:create
bin/rails spree:install:migrations
bin/rails spree_marketplace:install:migrations
bin/rails db:migrate
bin/rails db:seed

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

  Backend + admin:  cd server && bin/rails server          → http://localhost:3000/admin  (spree@example.com / spree123)
  Storefront:       pnpm --filter @ecloudmall/storefront dev → http://localhost:3001
MSG
