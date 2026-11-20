require 'spec_helper'

RSpec.describe Spree::Gateway::Ozow do
  let(:store) { Spree::Store.default || create(:store, default: true) }
  let(:gateway) do
    described_class.create!(name: 'Ozow', stores: [store], preferred_site_code: 'TSTSTE0001', preferred_private_key: 'privatekey123')
  end
  let(:order) { order_ready_for_payment(store) }
  let(:session) { gateway.create_payment_session(order: order, external_data: { 'return_url' => 'http://localhost:3001/checkout/payment/return' }) }

  before { store.allowed_origins.find_or_create_by!(origin: 'http://localhost') }

  def signed_response(overrides = {})
    data = {
      'SiteCode' => 'TSTSTE0001', 'TransactionId' => 'a1b2c3', 'TransactionReference' => session.external_id,
      'Amount' => format('%.2f', session.amount), 'Status' => 'Complete', 'Optional1' => session.prefixed_id,
      'CurrencyCode' => 'ZAR', 'IsTest' => 'true', 'StatusMessage' => 'Test transaction'
    }.merge(overrides)
    data.merge('Hash' => gateway.response_hash(data))
  end

  it 'builds a POST redirect with a SHA512 HashCheck over the documented fields' do
    fields = session.external_data['redirect']['fields']
    concatenated = Spree::Gateway::Ozow::REQUEST_HASH_FIELDS.map { |k| fields[k] }.join + 'privatekey123'
    expect(fields['HashCheck']).to eq(Digest::SHA512.hexdigest(concatenated.downcase))
    expect(fields).to include('CountryCode' => 'ZA', 'CurrencyCode' => 'ZAR', 'IsTest' => 'true',
                              'TransactionReference' => session.external_id)
    expect(fields['SuccessUrl']).to start_with('http://localhost:3001/checkout/payment/return?')
  end

  it 'accepts a correctly hashed notification and rejects a forged one' do
    body = URI.encode_www_form(signed_response)
    expect(gateway.parse_webhook_event(body, {})).to include(action: :captured, payment_session: session)

    forged = URI.encode_www_form(signed_response.merge('Amount' => '0.01'))
    expect { gateway.parse_webhook_event(forged, {}) }.to raise_error(Spree::PaymentMethod::WebhookSignatureError)
  end

  it 'settles the order from a verified return redirect' do
    gateway.complete_payment_session(payment_session: session, params: { external_data: signed_response })
    expect(session.reload).to be_completed
    expect(order.reload).to be_complete
    expect(order.payments.last).to have_attributes(state: 'completed', payment_method: gateway)
  end

  it 'does not settle from an unsigned return' do
    gateway.complete_payment_session(payment_session: session, params: { external_data: signed_response.merge('Hash' => 'nope') })
    expect(session.errors[:base]).to be_present
    expect(order.reload).not_to be_complete
  end
end
