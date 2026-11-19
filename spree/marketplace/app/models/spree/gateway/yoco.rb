require 'openssl'
require 'base64'

module Spree
  # Yoco Online Checkout (cards, Apple Pay, Google Pay, Samsung Pay).
  #
  # Docs: https://developer.yoco.com/online/checkout/  (POST /api/checkouts)
  #       https://developer.yoco.com/online/resources/webhooks (signature verification)
  class Gateway::Yoco < Gateway
    include Spree::Marketplace::HostedPaymentGateway

    API_URL = 'https://payments.yoco.com/api'.freeze
    WEBHOOK_TOLERANCE = 3.minutes

    preference :secret_key, :password
    preference :webhook_secret, :password
    preference :test_mode, :boolean, default: true

    def default_name
      'Yoco'
    end

    def payment_icon_name
      'yoco'
    end

    def create_payment_session(order:, amount: nil, external_data: {})
      session = build_session(order: order, amount: amount, external_data: external_data)
      return session if session.errors.any? || !session.save

      response = http_client.post_json("#{API_URL}/checkouts", {
        amount: session.amount_in_cents,
        currency: 'ZAR',
        successUrl: return_url_for(session, 'success'),
        cancelUrl: cancel_url_for(session),
        failureUrl: return_url_for(session, 'error'),
        externalId: session.external_id,
        metadata: { paymentSessionId: session.prefixed_id, orderNumber: order.number }
      }, headers: auth_headers.merge('Idempotency-Key' => session.external_id))

      if response.success? && response.json&.dig('redirectUrl')
        session.update!(external_data: session.external_data.merge(
          'checkout_id' => response.json['id'],
          'redirect' => { 'method' => 'GET', 'url' => response.json['redirectUrl'], 'fields' => {} }
        ))
      else
        message = response.json&.dig('description') || response.json&.dig('message') || "Yoco returned #{response.status}"
        session.errors.add(:base, "Could not start Yoco checkout: #{message}")
        session.fail if session.can_fail?
      end
      session
    rescue StandardError => e
      session&.errors&.add(:base, "Could not reach Yoco: #{e.message}")
      session
    end

    # On return, confirm with Yoco server-side before settling.
    def complete_payment_session(payment_session:, params: {})
      return payment_session if payment_session.completed?

      checkout = fetch_checkout(payment_session)
      status = checkout&.dig('status').to_s
      if %w[completed succeeded].include?(status)
        settle!(payment_session, :captured, provider_reference: checkout['paymentId'] || checkout['id'],
                                            amount: checkout['amount'].to_i / 100.0)
      elsif params[:session_result].to_s == 'canceled'
        payment_session.cancel if payment_session.can_cancel?
      elsif payment_session.can_process?
        payment_session.process
      end
      payment_session.reload
    end

    # Webhook events: payment.succeeded / payment.failed (Standard Webhooks / Svix signing).
    def parse_webhook_event(raw_body, headers)
      verify_signature!(raw_body, headers)
      event = JSON.parse(raw_body)
      payload = event['payload'] || {}
      metadata = payload['metadata'] || {}

      session = payment_sessions.find_by(external_id: metadata['externalId']) if metadata['externalId']
      session ||= payment_sessions.find_by_prefix_id(metadata['paymentSessionId']) if metadata['paymentSessionId']
      session ||= payment_sessions.where("external_data->>'checkout_id' = ?", metadata['checkoutId'].to_s).first if metadata['checkoutId']
      return nil if session.nil?

      action = case event['type']
               when 'payment.succeeded' then :captured
               when 'payment.failed' then :failed
               end
      return nil if action.nil?

      if action == :captured && !amount_matches?(session, payload['amount'].to_i / 100.0)
        Rails.logger.warn("[Yoco] amount mismatch for #{session.prefixed_id}")
        action = :failed
      end
      session.update_columns(external_data: session.external_data.merge('provider_reference' => payload['id']))
      webhook_result(action, session)
    rescue JSON::ParserError
      raise WebhookSignatureError, 'Malformed payload'
    end

    def credit(money, _source, response_code, _options = {})
      session = payment_sessions.find_by(external_id: response_code)
      checkout_id = session&.external_data&.dig('checkout_id')
      return super if checkout_id.blank?

      response = http_client.post_json("#{API_URL}/checkouts/#{checkout_id}/refund", { amount: money.to_i },
                                       headers: auth_headers.merge('Idempotency-Key' => "refund-#{response_code}-#{money}"))
      if response.success?
        Spree::PaymentResponse.new(true, 'Yoco: refund requested', response.json || {}, test: test_mode?, authorization: response.json&.dig('refundId'))
      else
        Spree::PaymentResponse.new(false, "Yoco refund failed: #{response.json&.dig('description') || response.status}", response.json || {}, test: test_mode?)
      end
    end

    def verify_signature!(raw_body, headers)
      id = headers['webhook-id'].to_s
      timestamp = headers['webhook-timestamp'].to_s
      signatures = headers['webhook-signature'].to_s
      raise WebhookSignatureError, 'Missing signature headers' if id.blank? || timestamp.blank? || signatures.blank?
      raise WebhookSignatureError, 'Stale webhook' if (Time.current.to_i - timestamp.to_i).abs > WEBHOOK_TOLERANCE

      expected = sign(id, timestamp, raw_body)
      valid = signatures.split(' ').any? do |sig|
        _version, value = sig.split(',', 2)
        value.present? && ActiveSupport::SecurityUtils.secure_compare(value, expected)
      end
      raise WebhookSignatureError, 'Invalid Yoco signature' unless valid
    end

    def sign(id, timestamp, body)
      secret = Base64.decode64(preferred_webhook_secret.to_s.delete_prefix('whsec_'))
      Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', secret, "#{id}.#{timestamp}.#{body}"))
    end

    private

    def auth_headers
      { 'Authorization' => "Bearer #{preferred_secret_key}" }
    end

    def fetch_checkout(payment_session)
      checkout_id = payment_session.external_data['checkout_id']
      return nil if checkout_id.blank?

      response = http_client.get("#{API_URL}/checkouts/#{checkout_id}", headers: auth_headers)
      response.success? ? response.json : nil
    rescue StandardError => e
      Rails.logger.error("[Yoco] checkout lookup failed: #{e.message}")
      nil
    end
  end
end
