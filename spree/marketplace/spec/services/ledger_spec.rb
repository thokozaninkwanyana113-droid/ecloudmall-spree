require 'spec_helper'

RSpec.describe Spree::Marketplace::Ledger do
  let(:store) { Spree::Store.default || create(:store, default: true) }
  let(:seller) { create(:seller, :approved, store: store, commission_rate: 10) }
  let(:product) { create(:product, stores: [store], seller: seller) }

  # A completed, paid order: one seller line item worth R400 + R100 delivery = R500 total.
  def paid_order
    order = create(:completed_order_with_totals, store: store, line_items_count: 1)
    order.line_items.update_all(variant_id: product.master.id, seller_id: seller.id, quantity: 2, price: 200)
    order.update_columns(payment_state: 'paid', total: 500, item_total: 400, completed_at: 1.hour.ago)
    order.reload
  end

  describe '.sync_order!' do
    it 'records sale and commission once, held for the returns window' do
      order = paid_order
      2.times { described_class.sync_order!(order) }

      expect(seller.ledger_entries.pluck(:kind, :amount).map { |k, a| [k, a.to_d] }).to contain_exactly(['sale', 400], ['commission', -40])
      expect(seller.balance).to eq(360)
      expect(seller.available_balance).to eq(0)
      expect(seller.available_balance(at: 8.days.from_now)).to eq(360)
    end

    it 'uses the referral commission for referred sellers' do
      partner = create(:partner, store: store, referral_commission_rate: 5)
      seller.update_columns(referred_by_partner_id: partner.id, referral_expires_at: 1.month.from_now)
      described_class.sync_order!(paid_order)
      expect(seller.reload.balance).to eq(380)
    end

    it 'claws back refunds pro rata, net of commission, leaving the delivery share with EcloudMall' do
      order = paid_order
      described_class.sync_order!(order)
      payment = create(:payment, order: order, amount: 500, state: 'completed')
      refund = Spree::Refund.new(payment: payment, amount: 250, reason: create(:refund_reason))
      refund.save!(validate: false) # skip gateway processing
      order.reload.update_columns(total: 500, payment_state: 'paid') # creating the payment recalculated the fixture's totals
      described_class.sync_order!(order.reload)

      # R250 of a R500 order; the seller's R400 line carries 80% = R200, less 10% commission returned
      expect(seller.ledger_entries.where(kind: %w[refund commission_reversal]).sum(:amount)).to eq(-180)
      expect(seller.balance).to eq(180)
    end

    it 'ignores incomplete orders' do
      order = create(:order_with_line_items, store: store)
      expect { described_class.sync_order!(order) }.not_to change(Spree::LedgerEntry, :count)
    end
  end

  describe 'payout runs' do
    before do
      described_class.sync_order!(paid_order)
      Spree::LedgerEntry.where(payee: seller).each { |e| e.update_column(:available_at, 1.day.ago) }
    end

    it 'skips payees without a verified bank account' do
      batch = described_class.create_payout_batch!(store: store)
      expect(batch.payouts).to be_empty
      expect(described_class.blocked_payees(store)).to include(seller)
    end

    it 'pays the available balance, debits the ledger and re-credits a bounced payout' do
      seller.create_bank_account!(account_holder: 'Ubuntu Threads (Pty) Ltd', bank_name: 'FNB', branch_code: '250655',
                                  account_number: '62000000001', account_type: 'cheque').verify!
      batch = described_class.create_payout_batch!(store: store)
      payout = batch.payouts.sole
      expect(payout.amount).to eq(360)
      expect(payout.bank_account_last4).to eq('0001')

      # a second run while the first is unpaid must not pay the same money twice
      expect(described_class.create_payout_batch!(store: store).payouts).to be_empty

      batch.approve!
      csv = ::CSV.parse(batch.to_bank_csv, headers: true)
      expect(csv.first.to_h).to include('Account number' => '62000000001', 'Branch code' => '250655', 'Amount' => '360.00')

      batch.mark_paid!
      expect(batch.reload.status).to eq('paid')
      expect(seller.reload.balance).to eq(0)

      payout.reload.mark_failed!('Account closed')
      expect(seller.reload.balance).to eq(360)
    end

    it 'un-verifies a bank account when its number changes' do
      account = seller.create_bank_account!(account_holder: 'X', bank_name: 'FNB', branch_code: '250655',
                                            account_number: '62000000001', account_type: 'cheque')
      account.verify!
      account.update!(account_number: '62000000002')
      expect(account.reload).not_to be_verified
    end
  end

  describe '.close_partner_month!' do
    let(:partner) { create(:partner, store: store, parcel_cost: 45) }

    it 'refuses the current month and accrues a finished month once' do
      expect { described_class.close_partner_month!(partner, month: Date.current) }.to raise_error(ArgumentError)

      allow(partner).to receive(:statement).and_return(parcels: 10, parcel_cost_rate: 45.to_d, parcel_costs: 450.to_d,
                                                      logistics_credit_applied: 50.to_d, referral_share: 12.to_d, referred_gmv: 1200.to_d)
      2.times { described_class.close_partner_month!(partner, month: Date.current.prev_month) }
      expect(partner.ledger_entries.pluck(:kind, :amount).map { |k, a| [k, a.to_d] }).to contain_exactly(['parcel_costs', 400], ['referral_share', 12])
    end
  end

  it 'keeps ledger entries append-only' do
    described_class.sync_order!(paid_order)
    entry = Spree::LedgerEntry.first
    expect { entry.update!(amount: 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { entry.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
