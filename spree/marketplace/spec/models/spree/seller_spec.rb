require 'spec_helper'

RSpec.describe Spree::Seller, type: :model do
  let(:store) { Spree::Store.default || create(:store, default: true) }

  describe 'creation' do
    let(:seller) { create(:seller, store: store, name: 'Ubuntu Threads', province: 'kzn') }

    it 'starts pending with the default commission and a prefixed id' do
      expect(seller.status).to eq('pending')
      expect(seller.commission_rate).to eq(Spree::Marketplace::DEFAULT_COMMISSION_RATE)
      expect(seller.prefixed_id).to start_with('sel_')
      expect(seller.slug).to eq('ubuntu-threads')
      expect(seller.province).to eq('KZN')
    end

    it 'rejects duplicate names within a store case-insensitively' do
      seller
      dup = build(:seller, store: store, name: 'UBUNTU threads')
      expect(dup).not_to be_valid
      expect(dup.errors[:name]).to be_present
    end

    it 'rejects unknown provinces' do
      expect(build(:seller, store: store, province: 'XX')).not_to be_valid
    end
  end

  describe 'status transitions' do
    let(:seller) { create(:seller, store: store) }

    it 'approves, timestamps and can be suspended' do
      seller.approve!
      expect(seller.reload).to be_approved
      expect(seller.approved_at).to be_present

      seller.suspend!
      expect(seller.reload.status).to eq('suspended')
    end

    it 'cannot suspend a pending seller' do
      expect(seller.suspend).to be(false)
    end
  end

  describe '#badges' do
    it 'lists ownership and B-BBEE badges' do
      seller = build(:seller, black_owned: true, women_owned: true, bbbee_level: 1, verified: true)
      expect(seller.badges).to eq(%w[black_owned women_owned bbbee_level_1 verified])
    end
  end

  describe '#sales_summary' do
    let(:seller) { create(:seller, :approved, store: store, commission_rate: 10) }
    let(:product) { create(:product, stores: [store], seller: seller, price: 100) }

    def completed_order_with(quantity:, payment_state:)
      order = create(:completed_order_with_totals, store: store, line_items_count: 1)
      order.line_items.update_all(variant_id: product.master.id, seller_id: seller.id, quantity: quantity, price: 100)
      order.update_columns(payment_state: payment_state)
      order
    end

    it 'pays out only on paid orders, net of commission' do
      paid = completed_order_with(quantity: 2, payment_state: 'paid')
      completed_order_with(quantity: 1, payment_state: 'balance_due')

      summary = seller.sales_summary(currency: paid.currency)
      expect(summary[:orders_count]).to eq(2)
      expect(summary[:gross]).to eq(300)
      expect(summary[:awaiting_payment]).to eq(100)
      expect(summary[:commission]).to eq(20)
      expect(summary[:payout]).to eq(180)
    end

    it 'snapshots the seller onto new line items' do
      order = create(:order, store: store)
      line_item = order.line_items.create!(variant: product.master, quantity: 1, price: 100, currency: order.currency)
      expect(line_item.seller).to eq(seller)
    end
  end
end
