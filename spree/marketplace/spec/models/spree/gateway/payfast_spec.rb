require 'spec_helper'

RSpec.describe Spree::Gateway::Payfast do
  let(:store) { Spree::Store.default || create(:store, default: true) }
  let(:passphrase) { 'jt7NOE43FZPn' }
  let(:gateway) do
    described_class.create!(name: 'PayFast', stores: [store],
                            preferred_merchant_id: '10000100', preferred_merchant_key: '46f0cd694581a',
                            preferred_passphrase: passphrase, preferred_validate_with_server: true)
  end
  let(:order) { order_ready_for_payment(store) }
  let(:session) do
    gateway.create_payment_session(order: order, external_data: { 'return_url' => 'https://evil.example/steal' })
  end

  before { store.allowed_origins.find_or_create_by!(origin: 'http://localhost') }

  describe '#request_signature' do
    # Same algorithm as PayFast's official SDK (Auth::generateSignature)
    it 'signs non-blank fields in submission order with the passphrase' do
      fields = { 'merchant_id' => '10000100', 'merchant_key' => '46f0cd694581a', 'amount' => '10.00',
                 'item_name' => 'Order #123', 'item_description' => '' }
      expected = Digest::MD5.hexdigest('merchant_id=10000100&merchant_key=46f0cd694581a&amount=10.00&item_name=Order+%23123&passphrase=jt7NOE43FZPn')
      expect(gateway.request_signature(fields)).to eq(expected)
    end
  end

  describe '#create_payment_session' do
    it 'returns a signed form redirect and refuses untrusted return URLs' do
      redirect = session.external_data['redirect']
      expect(redirect['url']).to eq('https://sandbox.payfast.co.za/eng/process')
      fields = redirect['fields']
      expect(fields).to include('merchant_id' => '10000100', 'm_payment_id' => session.external_id,
                                'amount' => format('%.2f', order.total), 'custom_str1' => session.prefixed_id)
      expect(fields['return_url']).not_to include('evil.example')
      expect(fields['notify_url']).to end_with("/api/v3/webhooks/payments/#{gateway.prefixed_id}")
      expect(fields['signature']).to eq(gateway.request_signature(fields.except('signature')))
    end
  end

  describe '#parse_webhook_event (ITN)' do
    def itn(overrides = {})
      pairs = {
        'm_payment_id' => session.external_id, 'pf_payment_id' => '1089250', 'payment_status' => 'COMPLETE',
        'item_name' => 'EcloudMall order', 'item_description' => '', 'amount_gross' => format('%.2f', session.amount),
        'amount_fee' => '-2.30', 'amount_net' => '97.70', 'custom_str1' => session.prefixed_id, 'name_first' => 'Ayanda',
        'email_address' => 'buyer@example.co.za', 'merchant_id' => '10000100'
      }.merge(overrides).to_a
      pairs << ['signature', gateway.itn_signature(pairs)]
      URI.encode_www_form(pairs)
    end

    before do
      stub_request(:post, 'https://sandbox.payfast.co.za/eng/query/validate').to_return(body: 'VALID')
    end

    it 'maps a verified COMPLETE notification to :captured' do
      result = gateway.parse_webhook_event(itn, {})
      expect(result).to include(action: :captured, payment_session: session)
      expect(session.reload.external_data['provider_reference']).to eq('1089250')
    end

    it 'rejects a tampered body' do
      expect { gateway.parse_webhook_event(itn.sub('COMPLETE', 'COMPLETX'), {}) }
        .to raise_error(Spree::PaymentMethod::WebhookSignatureError)
    end

    it 'rejects notifications PayFast does not confirm' do
      stub_request(:post, 'https://sandbox.payfast.co.za/eng/query/validate').to_return(body: 'INVALID')
      expect { gateway.parse_webhook_event(itn, {}) }.to raise_error(Spree::PaymentMethod::WebhookSignatureError)
    end

    it 'fails the payment when the amount does not match' do
      expect(gateway.parse_webhook_event(itn('amount_gross' => '1.00'), {})[:action]).to eq(:failed)
    end

    it 'maps CANCELLED to :canceled' do
      expect(gateway.parse_webhook_event(itn('payment_status' => 'CANCELLED'), {})[:action]).to eq(:canceled)
    end
  end
end
