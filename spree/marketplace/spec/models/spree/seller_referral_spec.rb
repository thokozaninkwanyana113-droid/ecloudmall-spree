require 'spec_helper'

RSpec.describe Spree::Seller, 'partner referrals', type: :model do
  let(:store) { Spree::Store.default || create(:store, default: true) }
  let!(:partner) { create(:partner, store: store, code: 'PARGO', referral_commission_rate: 5, referral_months: 6) }

  it 'links the partner and sets the referral window from a valid code' do
    seller = store.sellers.create!(name: 'Spaza Sweets', email: 'hi@spaza.co.za', referral_code: 'pargo')
    expect(seller.referred_by_partner).to eq(partner)
    expect(seller.referral_expires_at).to be_within(1.minute).of(6.months.from_now)
    expect(seller.effective_commission_rate).to eq(5)
  end

  it 'reverts to the standard commission after the referral period' do
    seller = store.sellers.create!(name: 'Spaza Sweets', email: 'hi@spaza.co.za', referral_code: 'PARGO')
    expect(seller.effective_commission_rate(7.months.from_now)).to eq(Spree::Marketplace::DEFAULT_COMMISSION_RATE)
  end

  it 'rejects unknown referral codes' do
    seller = store.sellers.build(name: 'Spaza Sweets', email: 'hi@spaza.co.za', referral_code: 'NOPE')
    expect(seller).not_to be_valid
    expect(seller.errors[:referral_code]).to be_present
  end
end
