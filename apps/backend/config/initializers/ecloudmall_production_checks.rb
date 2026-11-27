# Fail fast in production when settings that protect money or customer data are missing,
# instead of silently running with unsafe defaults.
if Rails.env.production? && ENV['SECRET_KEY_BASE_DUMMY'].blank?
  missing = %w[
    SECRET_KEY_BASE
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
    DATABASE_URL
    REDIS_URL
  ].select { |key| ENV[key].blank? }

  raise "EcloudMall production is missing required environment variables: #{missing.join(', ')}" if missing.any?
end
