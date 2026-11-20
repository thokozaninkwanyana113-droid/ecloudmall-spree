require 'digest'

module Spree
  # Ozow Instant EFT (pay directly from any major SA bank, incl. PayShap where enabled).
  #
  # Docs: https://hub.ozow.com/docs/step-1-post-variables (request + HashCheck)
  #       https://hub.ozow.com/docs/step-2-redirect-and-notification-response (notification + Hash)
  class Gateway::Ozow < Gateway
    include Spree::Marketplace::HostedPaymentGateway

    PAY_URL = 'https://pay.ozow.com'.freeze
    API_URL = 'https://api.ozow.com'.freeze

    REQUEST_HASH_FIELDS = %w[
      SiteCode CountryCode CurrencyCode Amount TransactionReference BankReference
      Optional1 Optional2 Optional3 Optional4 Optional5 Customer
      CancelUrl ErrorUrl SuccessUrl NotifyUrl IsTest
    ].freeze

    RESPONSE_HASH_FIELDS = %w[
      SiteCode TransactionId TransactionReference Amount Status
      Optional1 Optional2 Optional3 Optional4 Optional5
      CurrencyCode IsTest StatusMessage
    ].freeze

    preference :site_code, :string
    preference :private_key, :password
    preference :api_key, :password
    preference :test_mode, :boolean, default: true

    def default_name
      'Ozow'
    end

    def payment_icon_name
      'ozow'
    end

    def create_payment_session(order:, amount: nil, external_data: {})
      session = build_session(order: order, amount: amount, external_data: external_data)
      return session if session.errors.any? || !session.save

      fields = request_fields(session)
      session.update!(external_data: session.external_data.merge('redirect' => {
        'method' => 'POST', 'url' => PAY_URL, 'fields' => fields
      }))
      session
    end

    # Ozow redirects back with the same signed fields as the notification. If they are present
    # and the hash verifies we settle immediately; otherwise fall back to the status API.
    def complete_payment_session(payment_session:, params: {})
      return payment_session if payment_session.completed?

      data = (params[:external_data] || {}).to_h.stringify_keys
      if data['Hash'].present?
        raise WebhookSignatureError, 'Invalid Ozow hash' unless valid_response_hash?(data)
        return payment_session if data['TransactionReference'] != payment_session.external_id

        settle!(payment_session, action_for(data['Status']), provider_reference: data['TransactionId'],
                                                              amount: data['Amount'], details: { 'status' => data['Status'] })
      elsif (status = fetch_status(payment_session))
        settle!(payment_session, action_for(status['status']), provider_reference: status['transactionId'],
                                                                amount: status['amount'], details: { 'status' => status['status'] })
      elsif params[:session_result].to_s == 'canceled'
        payment_session.cancel if payment_session.can_cancel?
      elsif payment_session.can_process?
        payment_session.process
      end
      payment_session.reload
    rescue WebhookSignatureError => e
      payment_session.errors.add(:base, e.message)
      payment_session
    end

    # Ozow refunds are paid out by bank transfer or from the Ozow merchant portal. Recording the refund here
    # still claws it back from the seller's ledger and shows it to the customer.
    def credit(_money_cents, *args)
      response_code, = credit_arguments(args)
      Spree::PaymentResponse.new(true, 'Ozow: refund recorded — pay it from the Ozow merchant portal or by EFT', {},
                                 test: test_mode?, authorization: "ozow-refund-#{response_code}-#{SecureRandom.hex(4)}")
    end

    def parse_webhook_event(raw_body, _headers)
      data = URI.decode_www_form(raw_body.to_s).to_h
      raise WebhookSignatureError, 'Invalid Ozow hash' unless valid_response_hash?(data)
      raise WebhookSignatureError, 'Site code mismatch' if data['SiteCode'] != preferred_site_code

      session = find_session(data['TransactionReference'])
      return nil if session.nil?

      action = action_for(data['Status'])
      return nil if action.nil?

      if action == :captured && !amount_matches?(session, data['Amount'])
        Rails.logger.warn("[Ozow] amount mismatch for #{session.prefixed_id}")
        action = :failed
      end
      session.update_columns(external_data: session.external_data.merge('provider_reference' => data['TransactionId'], 'status' => data['Status']))
      webhook_result(action, session)
    end

    def request_hash(fields)
      ozow_hash(REQUEST_HASH_FIELDS.map { |k| fields[k] })
    end

    def response_hash(data)
      ozow_hash(RESPONSE_HASH_FIELDS.map { |k| data[k] })
    end

    def valid_response_hash?(data)
      data['Hash'].present? && ActiveSupport::SecurityUtils.secure_compare(response_hash(data), data['Hash'].to_s.downcase)
    end

    private

    def action_for(status)
      case status.to_s.downcase
      when 'complete', 'completed' then :captured
      when 'cancelled', 'canceled', 'abandoned' then :canceled
      when 'error' then :failed
      end
    end

    def request_fields(session)
      order = session.order
      fields = {
        'SiteCode' => preferred_site_code,
        'CountryCode' => 'ZA',
        'CurrencyCode' => 'ZAR',
        'Amount' => format('%.2f', session.amount),
        'TransactionReference' => session.external_id,
        'BankReference' => "ECM #{order.number}".first(20),
        'Optional1' => session.prefixed_id,
        'Customer' => order.email,
        'CancelUrl' => cancel_url_for(session),
        'ErrorUrl' => return_url_for(session, 'error'),
        'SuccessUrl' => return_url_for(session, 'success'),
        'NotifyUrl' => notify_url,
        'IsTest' => preferred_test_mode ? 'true' : 'false'
      }
      fields['HashCheck'] = request_hash(fields)
      fields
    end

    def ozow_hash(values)
      Digest::SHA512.hexdigest("#{values.map(&:to_s).join}#{preferred_private_key}".downcase)
    end

    def fetch_status(payment_session)
      return nil if preferred_api_key.blank?

      url = "#{API_URL}/GetTransactionByReference?siteCode=#{CGI.escape(preferred_site_code.to_s)}" \
            "&transactionReference=#{CGI.escape(payment_session.external_id)}"
      response = http_client.get(url, headers: { 'ApiKey' => preferred_api_key })
      return nil unless response.success?

      Array(response.json).map { |t| t.transform_keys { |k| k.to_s.camelize(:lower) } }
                          .max_by { |t| t['createdDate'].to_s }
    rescue StandardError => e
      Rails.logger.error("[Ozow] status lookup failed: #{e.message}")
      nil
    end
  end
end
