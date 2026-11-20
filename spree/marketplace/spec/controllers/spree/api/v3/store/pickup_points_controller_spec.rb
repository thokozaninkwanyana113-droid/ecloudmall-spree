require 'spec_helper'

RSpec.describe Spree::Api::V3::Store::PickupPointsController, type: :controller do
  render_views
  include_context 'API v3 Store'

  before { request.headers['X-Spree-Api-Key'] = api_key.token }

  let(:partner) { create(:partner, store: store, code: 'PAXI') }
  let(:method) { create(:shipping_method, partner: partner, pickup_point_provider: 'Spree::PickupPointProvider::SampleDirectory') }

  it 'returns the nearest sample points for a postal code, labelled as samples' do
    get :index, params: { delivery_method_id: method.prefixed_id, postal_code: '7784', limit: 2 }
    expect(response).to have_http_status(:ok)
    points = json_response[:data]
    expect(points.size).to eq(2)
    expect(points.first[:name]).to include('SAMPLE').and include('Khayelitsha')
    expect(points.first[:external_id]).to start_with('paxi-')
    expect(points.first[:metadata][:sample]).to be(true)
  end

  it 'refuses delivery methods without a pickup point provider' do
    get :index, params: { delivery_method_id: create(:shipping_method).prefixed_id }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
