require 'spec_helper'

RSpec.describe Spree::Api::V3::Store::SellersController, type: :controller do
  render_views
  include_context 'API v3 Store'

  before { request.headers['X-Spree-Api-Key'] = api_key.token }

  let!(:approved) { create(:seller, :approved, store: store, name: 'Mzansi Clay', province: 'WC', women_owned: true) }
  let!(:other_approved) { create(:seller, :approved, store: store, name: 'Jozi Labs', province: 'GP') }
  let!(:pending) { create(:seller, store: store, name: 'Pending Spaza') }

  describe 'GET #index' do
    it 'lists only approved sellers' do
      get :index
      expect(response).to have_http_status(:ok)
      names = json_response[:data].map { |s| s[:name] }
      expect(names).to contain_exactly('Mzansi Clay', 'Jozi Labs')
    end

    it 'filters by province and ownership' do
      get :index, params: { q: { province_eq: 'WC', women_owned_eq: true } }
      expect(json_response[:data].map { |s| s[:slug] }).to eq(['mzansi-clay'])
    end

    it 'does not expose private fields' do
      get :index
      seller = json_response[:data].first
      expect(seller[:id]).to start_with('sel_')
      expect(seller.keys).not_to include('email', 'commission_rate', 'admin_notes', 'registration_number', 'vat_number')
    end
  end

  describe 'GET #show' do
    it 'finds an approved seller by slug or prefixed id' do
      get :show, params: { id: 'mzansi-clay' }
      expect(json_response[:name]).to eq('Mzansi Clay')

      get :show, params: { id: approved.prefixed_id }
      expect(json_response[:slug]).to eq('mzansi-clay')
    end

    it 'returns 404 for pending sellers' do
      get :show, params: { id: pending.slug }
      expect(response).to have_http_status(:not_found)
    end
  end
end
