# syntax=docker/dockerfile:1
# EcloudMall backend (Rails + Spree + marketplace engine).
# Build from the REPOSITORY ROOT so the local Spree engines in spree/ are available:
#   docker build -f apps/backend/Dockerfile -t ecloudmall-backend .

ARG RUBY_VERSION=3.3.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /app/apps/backend

RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
  ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
  BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle" \
  BUNDLE_WITHOUT="development:test" \
  LD_PRELOAD="/usr/local/lib/libjemalloc.so"

FROM base AS build

RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Spree engines from the monorepo (the Gemfile points at ../../spree)
COPY spree /app/spree

# Gems
COPY apps/backend/.ruby-version apps/backend/Gemfile apps/backend/Gemfile.lock ./
RUN bundle install && \
  rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
  bundle exec bootsnap precompile --gemfile

# App code, bootsnap and assets (admin Tailwind CSS is built as part of assets:precompile)
COPY apps/backend ./
RUN bundle exec bootsnap precompile app/ lib/ && \
  SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base

RUN groupadd --system --gid 1000 rails && \
  useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /app /app

ENTRYPOINT ["/app/apps/backend/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
