require 'spec_helper'

RSpec.describe Spree::Api::V3::Store::ProductsController, type: :controller do
  render_views
  include_context 'API v3 Store'

  before { request.headers['X-Spree-Api-Key'] = api_key.token }

  let(:approved) { create(:seller, :approved, store: store, name: 'Karoo Pantry', province: 'EC', black_owned: true) }
  let(:suspended) { create(:seller, store: store, name: 'Gone Quiet', status: 'suspended') }
  let!(:seller_product) { create(:product, name: 'Biltong', stores: [store], seller: approved) }
  let!(:house_product) { create(:product, name: 'Gift Card Box', stores: [store]) }
  let!(:hidden_product) { create(:product, name: 'Hidden Thing', stores: [store], seller: suspended) }

  it 'hides products from sellers that are not approved' do
    get :index
    names = json_response[:data].map { |p| p[:name] }
    expect(names).to contain_exactly('Biltong', 'Gift Card Box')
  end

  it 'embeds the seller summary' do
    get :show, params: { id: seller_product.slug }
    expect(json_response[:seller_id]).to eq(approved.prefixed_id)
    expect(json_response[:seller]).to include(name: 'Karoo Pantry', province: 'EC', slug: 'karoo-pantry')
    expect(json_response[:seller][:badges]).to include('black_owned')
  end

  it 'filters by seller attributes' do
    get :index, params: { q: { seller_province_eq: 'EC', seller_black_owned_eq: true } }
    expect(json_response[:data].map { |p| p[:name] }).to eq(['Biltong'])
  end
end
