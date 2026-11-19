require 'spec_helper'

RSpec.describe Spree::Gateway::Yoco do
  let(:store) { Spree::Store.default || create(:store, default: true) }
  let(:webhook_secret) { "whsec_#{Base64.strict_encode64('super-secret-key')}" }
  let(:gateway) do
    described_class.create!(name: 'Yoco', stores: [store], preferred_secret_key: 'sk_test_123', preferred_webhook_secret: webhook_secret)
  end
  let(:order) { order_ready_for_payment(store) }
  let(:session) { gateway.create_payment_session(order: order, external_data: { 'return_url' => 'http://localhost:3001/checkout/payment/return' }) }

  before do
    store.allowed_origins.find_or_create_by!(origin: 'http://localhost')
    stub_request(:post, 'https://payments.yoco.com/api/checkouts')
      .with(headers: { 'Authorization' => 'Bearer sk_test_123' })
      .to_return(status: 200, body: { id: 'ch_123', redirectUrl: 'https://c.yoco.com/checkout/ch_123', status: 'created' }.to_json)
  end

  it 'creates a hosted checkout for the amount in cents and returns a GET redirect' do
    expect(session.external_data).to include('checkout_id' => 'ch_123')
    expect(session.external_data['redirect']).to include('method' => 'GET', 'url' => 'https://c.yoco.com/checkout/ch_123')
    expect(WebMock).to have_requested(:post, 'https://payments.yoco.com/api/checkouts')
      .with { |req| JSON.parse(req.body)['amount'] == session.amount_in_cents && JSON.parse(req.body)['currency'] == 'ZAR' }
  end

  describe 'webhooks' do
    def event(type = 'payment.succeeded', amount: session.amount_in_cents)
      { id: 'evt_1', type: type, payload: { id: 'p_1', amount: amount, currency: 'ZAR', status: 'succeeded',
                                            metadata: { checkoutId: 'ch_123', paymentSessionId: session.prefixed_id } } }.to_json
    end

    def headers_for(body, timestamp: Time.current.to_i)
      { 'webhook-id' => 'msg_1', 'webhook-timestamp' => timestamp.to_s,
        'webhook-signature' => "v1,#{gateway.sign('msg_1', timestamp, body)}" }
    end

    it 'accepts a correctly signed payment.succeeded event' do
      body = event
      expect(gateway.parse_webhook_event(body, headers_for(body))).to include(action: :captured, payment_session: session)
    end

    it 'rejects bad signatures and stale timestamps' do
      body = event
      expect { gateway.parse_webhook_event(body, headers_for(body).merge('webhook-signature' => 'v1,abc')) }
        .to raise_error(Spree::PaymentMethod::WebhookSignatureError)
      expect { gateway.parse_webhook_event(body, headers_for(body, timestamp: 10.minutes.ago.to_i)) }
        .to raise_error(Spree::PaymentMethod::WebhookSignatureError)
    end

    it 'fails the payment on an amount mismatch' do
      body = event(amount: 100)
      expect(gateway.parse_webhook_event(body, headers_for(body))[:action]).to eq(:failed)
    end
  end

  it 'settles on return only after Yoco confirms the checkout server-side' do
    stub_request(:get, 'https://payments.yoco.com/api/checkouts/ch_123')
      .to_return(status: 200, body: { id: 'ch_123', status: 'completed', amount: session.amount_in_cents, paymentId: 'p_9' }.to_json)

    gateway.complete_payment_session(payment_session: session, params: { session_result: 'success' })
    expect(session.reload).to be_completed
    expect(order.reload).to be_complete
  end
end
