require 'spec_helper'

RSpec.describe Spree::Partner, type: :model do
  let(:store) { Spree::Store.default || create(:store, default: true) }
  let(:partner) do
    create(:partner, store: store, code: 'paxi', parcel_cost: 45,
                     volume_tiers: [{ 'min_parcels' => 2, 'parcel_cost' => 40 }, { 'min_parcels' => 5, 'parcel_cost' => 36 }])
  end

  it 'normalises the code and finds live partners by referral code' do
    expect(partner.code).to eq('PAXI')
    expect(described_class.find_by_referral_code(' paxi ')).to eq(partner)
    partner.update!(status: 'prospect')
    expect(described_class.find_by_referral_code('PAXI')).to be_nil
  end

  it 'applies the best volume tier reached' do
    expect(partner.parcel_cost_for(1)).to eq(45)
    expect(partner.parcel_cost_for(3)).to eq(40)
    expect(partner.parcel_cost_for(9)).to eq(36)
    expect(partner.next_tier_for(3)).to eq('min_parcels' => 5, 'parcel_cost' => 36)
  end

  it 'rejects malformed volume tiers' do
    expect(build(:partner, store: store, volume_tiers: [{ 'parcel_cost' => 10 }])).not_to be_valid
  end

  describe '#statement' do
    let(:pickup_method) { create(:shipping_method, partner: partner, pickup_point_provider: 'Spree::PickupPointProvider::SampleDirectory') }
    let(:seller) { create(:seller, :approved, store: store, referred_by_partner: partner, referral_expires_at: 1.month.from_now) }
    let(:product) { create(:product, stores: [store], seller: seller) }

    def paid_partner_order(item_total:)
      order = create(:completed_order_with_totals, store: store, line_items_count: 1)
      order.line_items.update_all(variant_id: product.master.id, seller_id: seller.id, quantity: 1, price: item_total)
      order.update_columns(payment_state: 'paid', completed_at: Time.current)
      shipment = order.shipments.first
      shipment.shipping_rates.update_all(selected: false)
      rate = shipment.shipping_rates.find_or_initialize_by(shipping_method: pickup_method)
      rate.update!(cost: 59, selected: true)
      shipment.update_columns(cost: 59)
      order
    end

    it 'computes parcels, tiered costs, margin and referral share' do
      2.times { paid_partner_order(item_total: 500) }

      st = partner.statement
      expect(st[:parcels]).to eq(2)
      expect(st[:parcel_cost_rate]).to eq(40)
      expect(st[:delivery_revenue]).to eq(118)
      expect(st[:parcel_costs]).to eq(80)
      expect(st[:delivery_margin]).to eq(38)
      expect(st[:referred_gmv]).to eq(1000)
      expect(st[:referral_share]).to eq(10)
      expect(st[:payable_to_partner]).to eq(90)
    end

    it 'draws parcel costs from in-kind logistics credit first' do
      partner.update!(investor: true, logistics_credit: 50)
      2.times { paid_partner_order(item_total: 500) }

      st = partner.statement
      expect(st[:logistics_credit_applied]).to eq(50)
      expect(st[:logistics_credit_remaining]).to eq(0)
      expect(st[:payable_to_partner]).to eq(40) # 80 parcel costs - 50 credit + 10 referral share
    end
  end
end
