require 'spec_helper'

RSpec.describe Spree::Api::V3::Store::SellerApplicationsController, type: :controller do
  render_views
  include_context 'API v3 Store'

  before { request.headers['X-Spree-Api-Key'] = api_key.token }

  it 'creates a pending seller and ignores privileged attributes' do
    expect {
      post :create, params: { name: 'Spaza Sweets', email: 'hi@spaza.co.za', province: 'LP', black_owned: true,
                              status: 'approved', commission_rate: 0, featured: true }
    }.to change(Spree::Seller, :count).by(1)

    expect(response).to have_http_status(:created)
    seller = Spree::Seller.last
    expect(seller).to have_attributes(status: 'pending', featured: false, black_owned: true, store: store)
    expect(seller.commission_rate).to eq(Spree::Marketplace::DEFAULT_COMMISSION_RATE)
    expect(json_response[:id]).to eq(seller.prefixed_id)
  end

  it 'attaches a live partner from a referral code' do
    partner = create(:partner, store: store, code: 'PAXI')
    post :create, params: { name: 'Kasi Kicks', email: 'kicks@example.co.za', province: 'GP', referral_code: 'paxi' }
    expect(response).to have_http_status(:created)
    expect(json_response[:referred_by]).to eq(partner.name)
    expect(Spree::Seller.last.referred_by_partner).to eq(partner)
  end

  it 'returns validation errors' do
    post :create, params: { name: '', email: 'nope', province: 'XX' }
    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig(:error, :details).keys).to include('name', 'email', 'province')
  end

  it 'requires a publishable API key' do
    request.headers['X-Spree-Api-Key'] = nil
    post :create, params: { name: 'X', email: 'x@y.co' }
    expect(response).to have_http_status(:unauthorized)
  end
end
