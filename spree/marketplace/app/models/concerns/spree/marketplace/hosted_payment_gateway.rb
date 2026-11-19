module Spree
  module Marketplace
    # Shared behaviour for redirect ("hosted payment page") gateways — PayFast, Ozow, Yoco.
    #
    # Flow:
    # 1. Storefront creates a payment session (POST /carts/:id/payment_sessions) passing
    #    `external_data: { return_url:, cancel_url: }`. The gateway responds with
    #    `external_data.redirect = { method:, url:, fields: }`.
    # 2. Shopper pays on the provider's page.
    # 3. The provider's signed notification hits POST /api/v3/webhooks/payments/:payment_method_id
    #    (#parse_webhook_event) and/or the shopper returns and the storefront calls
    #    PATCH /carts/:id/payment_sessions/:id/complete (#complete_payment_session).
    # 4. Either path, once verified, settles the session through Spree::Payments::HandleWebhook,
    #    which creates/completes the payment and completes the order. Both paths are idempotent.
    module HostedPaymentGateway
      extend ActiveSupport::Concern

      included do
        preference :notify_base_url, :string, default: ''
      end

      def provider_class
        self.class
      end

      def session_required?
        true
      end

      def source_required?
        false
      end

      def payment_source_class
        nil
      end

      def payment_profiles_supported?
        false
      end

      def auto_capture?
        true
      end

      def method_type
        'hosted'
      end

      # Funds are captured on the provider's hosted page; the payment is completed by the
      # verified notification. These keep Spree's payment state machine happy.
      def purchase(_money, _source, _options = {})
        success_response('Captured by provider')
      end
      alias authorize purchase

      def capture(_money, _authorization, _options = {})
        success_response('Captured by provider')
      end

      def void(_response_code, _source = nil, _options = {})
        success_response('Voided locally — no funds were reserved')
      end

      def cancel(_response_code, _payment = nil)
        success_response('Canceled locally — refund in the provider dashboard if funds were received')
      end

      def credit(_money, _source, _response_code, _options = {})
        Spree::PaymentResponse.new(false, "Refunds for #{name} must be issued from the provider dashboard", {}, test: test_mode?)
      end

      def payment_session_class
        "Spree::PaymentSessions::#{self.class.name.demodulize}".constantize
      end

      def update_payment_session(payment_session:, amount: nil, external_data: {})
        attrs = {}
        attrs[:amount] = amount if amount.present?
        attrs[:external_data] = payment_session.external_data.merge(external_data.to_h.except('redirect')) if external_data.present?
        payment_session.update(attrs)
      end

      def test_mode?
        respond_to?(:preferred_test_mode) && preferred_test_mode
      end

      def notify_url
        base = preferred_notify_base_url.presence || stores.first&.formatted_url
        "#{base.to_s.chomp('/')}/api/v3/webhooks/payments/#{prefixed_id}"
      end

      protected

      # Creates the local session record. Gateways then attach the provider redirect.
      def build_session(order:, amount:, external_data:)
        session = payment_session_class.new(
          order: order,
          payment_method: self,
          amount: amount.presence || order.total_minus_store_credits,
          currency: order.currency,
          status: 'pending',
          external_id: generate_reference(order),
          external_data: sanitize_external_data(order, external_data),
          customer: order.user,
          expires_at: 2.hours.from_now
        )
        # Don't take money for an order that can't complete (e.g. pickup point not chosen yet)
        session.errors.add(:base, Spree.t('marketplace.pickup_points.required')) if order.missing_pickup_point?
        session
      end

      def generate_reference(order)
        "#{order.number}-#{SecureRandom.alphanumeric(6).upcase}"
      end

      # Only accept return/cancel URLs on origins the store trusts (prevents open redirects).
      def sanitize_external_data(order, external_data)
        data = external_data.to_h.stringify_keys.slice('return_url', 'cancel_url')
        store = order.store
        fallback = store.storefront_url
        data['return_url'] = fallback unless store.allowed_origin?(data['return_url'])
        data['cancel_url'] = data['return_url'] unless store.allowed_origin?(data['cancel_url'])
        data
      end

      def return_url_for(payment_session, result)
        append_query(payment_session.external_data['return_url'], payment_session: payment_session.prefixed_id, result: result)
      end

      def cancel_url_for(payment_session)
        append_query(payment_session.external_data['cancel_url'], payment_session: payment_session.prefixed_id, result: 'canceled')
      end

      def append_query(url, params)
        uri = URI.parse(url)
        query = URI.decode_www_form(uri.query.to_s) + params.map { |k, v| [k.to_s, v.to_s] }
        uri.query = URI.encode_www_form(query)
        uri.to_s
      end

      def amount_matches?(payment_session, amount)
        BigDecimal(amount.to_s).round(2) == payment_session.amount.to_d.round(2)
      rescue ArgumentError, TypeError
        false
      end

      # Settles a verified provider result. Safe to call repeatedly.
      def settle!(payment_session, action, provider_reference: nil, amount: nil, details: {})
        if action == :captured && amount && !amount_matches?(payment_session, amount)
          Rails.logger.warn("[#{self.class.name}] amount mismatch for #{payment_session.prefixed_id}: got #{amount}, expected #{payment_session.amount}")
          action = :failed
          details = details.merge('failure_reason' => 'amount_mismatch')
        end

        payment_session.update_columns(
          external_data: payment_session.external_data.merge(details.stringify_keys).merge('provider_reference' => provider_reference).compact,
          updated_at: Time.current
        )

        Spree::Dependencies.payments_handle_webhook_service.constantize.call(
          payment_method: self,
          action: action,
          payment_session: payment_session
        )
      end

      def webhook_result(action, payment_session)
        return nil if payment_session.nil?

        { action: action, payment_session: payment_session, metadata: {} }
      end

      def find_session(external_id)
        payment_sessions.find_by(external_id: external_id.to_s)
      end

      def success_response(message)
        Spree::PaymentResponse.new(true, "#{name}: #{message}", {}, test: test_mode?)
      end

      def http_client
        @http_client ||= Spree::Marketplace::HttpClient.new
      end
    end
  end
end
