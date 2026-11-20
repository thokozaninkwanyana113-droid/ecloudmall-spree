require 'digest/md5'
require 'cgi'

module Spree
  # PayFast hosted payments (cards, Instant EFT, SnapScan, Zapper, Mobicred, …).
  #
  # Docs: https://developers.payfast.co.za/docs#step_1_form_fields (custom integration)
  #       https://developers.payfast.co.za/docs#step_4_confirm_payment (ITN)
  #
  # Shared sandbox credentials (public): merchant_id 10000100, merchant_key 46f0cd694581a, no passphrase.
  # For signed requests create your own sandbox merchant at https://sandbox.payfast.co.za and set its passphrase.
  #
  # Signing follows PayFast's official SDK (payfast-php-sdk Auth::generateSignature): fields in submission
  # order, blank values skipped, PHP urlencode() of trimmed values, optional passphrase, MD5.
  class Gateway::Payfast < Gateway
    include Spree::Marketplace::HostedPaymentGateway

    API_HOST = 'https://api.payfast.co.za'.freeze
    LIVE_HOST = 'https://www.payfast.co.za'.freeze
    SANDBOX_HOST = 'https://sandbox.payfast.co.za'.freeze

    # Field order matters for the request signature (PayFast documentation order).
    REQUEST_FIELDS = %w[
      merchant_id merchant_key return_url cancel_url notify_url
      name_first name_last email_address cell_number
      m_payment_id amount item_name item_description
      custom_int1 custom_int2 custom_int3 custom_int4 custom_int5
      custom_str1 custom_str2 custom_str3 custom_str4 custom_str5
      email_confirmation confirmation_address payment_method
    ].freeze

    preference :merchant_id, :string
    preference :merchant_key, :string
    preference :passphrase, :password
    preference :test_mode, :boolean, default: true
    preference :validate_with_server, :boolean, default: true

    def default_name
      'PayFast'
    end

    def payment_icon_name
      'payfast'
    end

    def host
      preferred_test_mode ? SANDBOX_HOST : LIVE_HOST
    end

    def create_payment_session(order:, amount: nil, external_data: {})
      session = build_session(order: order, amount: amount, external_data: external_data)
      return session if session.errors.any? || !session.save

      fields = request_fields(session)
      session.update!(external_data: session.external_data.merge('redirect' => {
        'method' => 'POST', 'url' => "#{host}/eng/process", 'fields' => fields
      }))
      session
    end

    # Called when the shopper returns. PayFast does not sign the return redirect, so we only
    # move the session to `processing`; the ITN settles it.
    def complete_payment_session(payment_session:, params: {})
      return payment_session if payment_session.completed?

      if params[:session_result].to_s == 'canceled'
        payment_session.cancel if payment_session.can_cancel?
      elsif payment_session.can_process?
        payment_session.process
      end
      payment_session
    end

    # ITN (Instant Transaction Notification) — application/x-www-form-urlencoded POST.
    def parse_webhook_event(raw_body, _headers)
      pairs = URI.decode_www_form(raw_body.to_s)
      data = pairs.to_h
      raise WebhookSignatureError, 'Missing signature' if data['signature'].blank?

      expected = itn_signature(pairs)
      unless ActiveSupport::SecurityUtils.secure_compare(expected, data['signature'].to_s.downcase)
        raise WebhookSignatureError, 'Invalid PayFast signature'
      end
      raise WebhookSignatureError, 'Merchant mismatch' if data['merchant_id'].to_s != preferred_merchant_id.to_s
      raise WebhookSignatureError, 'PayFast server validation failed' if preferred_validate_with_server && !server_confirms?(pairs)

      session = find_session(data['m_payment_id'])
      return nil if session.nil?

      action = case data['payment_status'].to_s.upcase
               when 'COMPLETE' then :captured
               when 'CANCELLED' then :canceled
               when 'FAILED' then :failed
               end
      return nil if action.nil?

      if action == :captured && !amount_matches?(session, data['amount_gross'])
        Rails.logger.warn("[PayFast] amount mismatch for #{session.prefixed_id}")
        action = :failed
      end

      session.update_columns(external_data: session.external_data.merge(
        'provider_reference' => data['pf_payment_id'], 'provider_fee' => data['amount_fee'], 'provider_net' => data['amount_net']
      ).compact)
      webhook_result(action, session)
    end

    # Refund back to the shopper via PayFast's Refunds API (POST /refunds/{pf_payment_id}).
    # Request shape and signing follow PayFast's official SDK (Services/Refunds.php, Request.php,
    # Auth::generateApiSignature). PayFast offers no refunds in sandbox, so test mode records a simulated refund.
    def credit(money_cents, *args)
      response_code, options = credit_arguments(args)
      session = payment_sessions.find_by(external_id: response_code)
      pf_payment_id = session&.external_data&.dig('provider_reference')
      return Spree::PaymentResponse.new(false, 'PayFast: original PayFast payment id not found for this payment', {}, test: test_mode?) if pf_payment_id.blank?

      if preferred_test_mode
        return Spree::PaymentResponse.new(true, 'PayFast sandbox: refund simulated (PayFast has no sandbox refunds)', {},
                                          test: true, authorization: "pf-sandbox-refund-#{SecureRandom.hex(6)}")
      end

      body = { 'amount' => money_cents.to_i, 'reason' => refund_reason(options), 'notify_buyer' => 1 }
      response = http_client.post_json("#{API_HOST}/refunds/#{pf_payment_id}", body, headers: api_headers(body))
      if response.success?
        Spree::PaymentResponse.new(true, 'PayFast: refund submitted', response.json || {}, authorization: response.json&.dig('data', 'response').to_s.presence || pf_payment_id)
      else
        Spree::PaymentResponse.new(false, "PayFast refund failed: #{response.json&.dig('data', 'message') || response.status}", response.json || {})
      end
    end

    def refund_reason(options)
      refund = options[:originator]
      (refund.respond_to?(:reason) ? refund.reason&.name : nil).presence || 'Refund from EcloudMall'
    end

    # merchant-id / version / timestamp headers + signature = MD5 of all header and body values plus the
    # passphrase, sorted by key, PHP-urlencoded (payfast-php-sdk Auth::generateApiSignature).
    def api_headers(body, timestamp: Time.current)
      headers = { 'merchant-id' => preferred_merchant_id.to_s, 'version' => 'v1', 'timestamp' => timestamp.strftime('%Y-%m-%dT%H:%M:%S%z') }
      signed = headers.merge(body.transform_values(&:to_s))
      signed['passphrase'] = preferred_passphrase.to_s if preferred_passphrase.present?
      string = signed.sort.reject { |k, _| k == 'signature' }.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
      headers.merge('signature' => Digest::MD5.hexdigest(string))
    end

    # Signature for the payment request: non-blank fields in documented order.
    def request_signature(fields)
      signature_for(REQUEST_FIELDS.filter_map { |k| [k, fields[k]] if fields[k].present? })
    end

    # Signature for ITN: every field as received (blank ones included), except `signature`.
    def itn_signature(pairs)
      signature_for(pairs.reject { |k, _| k == 'signature' })
    end

    private

    def request_fields(session)
      order = session.order
      address = order.bill_address || order.ship_address
      fields = {
        'merchant_id' => preferred_merchant_id,
        'merchant_key' => preferred_merchant_key,
        'return_url' => return_url_for(session, 'success'),
        'cancel_url' => cancel_url_for(session),
        'notify_url' => notify_url,
        'name_first' => address&.firstname.to_s.truncate(100, omission: ''),
        'name_last' => address&.lastname.to_s.truncate(100, omission: ''),
        'email_address' => order.email,
        'm_payment_id' => session.external_id,
        'amount' => format('%.2f', session.amount),
        'item_name' => "EcloudMall order #{order.number}",
        'item_description' => order.line_items.map(&:name).join(', ').truncate(255),
        'custom_str1' => session.prefixed_id
      }
      fields.compact_blank!
      # PayFast requires the signature only when the account has a passphrase. Without one the MD5
      # adds no security (anyone can compute it) — payments are protected by ITN validation instead.
      fields['signature'] = request_signature(fields) if preferred_passphrase.present?
      fields
    end

    def signature_for(pairs)
      string = pairs.map { |k, v| "#{k}=#{pf_encode(v)}" }.join('&')
      string += "&passphrase=#{pf_encode(preferred_passphrase)}" if preferred_passphrase.present?
      Digest::MD5.hexdigest(string)
    end

    # PHP urlencode(): spaces as '+', uppercase percent-encoding. CGI.escape matches.
    def pf_encode(value)
      CGI.escape(value.to_s.strip)
    end

    def server_confirms?(pairs)
      body = pairs.reject { |k, _| k == 'signature' }.map { |k, v| "#{k}=#{pf_encode(v)}" }.join('&')
      response = http_client.post_form("#{host}/eng/query/validate", body)
      response.success? && response.body.strip == 'VALID'
    rescue StandardError => e
      Rails.logger.error("[PayFast] validate request failed: #{e.message}")
      false
    end
  end
end
