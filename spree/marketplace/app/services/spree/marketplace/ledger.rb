module Spree
  module Marketplace
    # Records every amount owed to sellers and partners in the append-only ledger, and builds payout runs.
    # All methods are idempotent: re-running them never double counts (see docs/plans/ecloudmall-funds-flow.md).
    module Ledger
      PAID_STATES = %w[paid credit_owed].freeze

      module_function

      def hold_days
        ENV.fetch('ECLOUDMALL_PAYOUT_HOLD_DAYS', 7).to_i
      end

      # Sale + commission per seller line item once paid; refund clawback for every refund on the order.
      def sync_order!(order)
        return unless order&.completed?

        record_sales(order) if PAID_STATES.include?(order.payment_state) || order.refunds.any?
        record_refunds(order)
      end

      # Re-sync orders completed in the last `days` (nightly job / before a payout run).
      def sync_recent!(store:, days: 45)
        store.orders.complete.where(completed_at: days.days.ago..).find_each { |order| sync_order!(order) }
      end

      # Turns a finished month's partner statement into ledger entries (parcel costs net of in-kind credit,
      # referral share). Only for months that have ended, so the numbers can no longer move.
      def close_partner_month!(partner, month:)
        month_start = month.to_date.beginning_of_month
        raise ArgumentError, 'Only months that have ended can be closed' if month_start.end_of_month >= Date.current

        st = partner.statement(month: month_start.in_time_zone)
        key = "#{partner.id}:#{month_start.strftime('%Y-%m')}"
        label = month_start.strftime('%B %Y')
        entries = []
        parcel_due = st[:parcel_costs] - st[:logistics_credit_applied]
        if parcel_due.positive?
          entries << record(partner, kind: 'parcel_costs', amount: parcel_due, key: "parcel_costs:#{key}",
                                     description: "#{st[:parcels]} parcels at #{st[:parcel_cost_rate]} — #{label}",
                                     metadata: st.slice(:parcels, :parcel_cost_rate, :logistics_credit_applied))
        end
        if st[:referral_share].positive?
          entries << record(partner, kind: 'referral_share', amount: st[:referral_share], key: "referral_share:#{key}",
                                     description: "Referral share on #{st[:referred_gmv]} paid GMV — #{label}")
        end
        entries
      end

      # Draft payout run for every payee with a verified bank account and enough available balance.
      # @return [Spree::PayoutBatch]
      def create_payout_batch!(store:, at: Time.current, minimum: Spree::PayoutBatch::MINIMUM_PAYOUT)
        sync_recent!(store: store)
        batch = store.class.transaction do
          b = Spree::PayoutBatch.create!(store: store, currency: store.default_currency, period_end: at)
          payees(store).each do |payee|
            next unless payee.payout_ready?

            amount = payee.payable_amount(currency: b.currency, at: at)
            Spree::Payout.build_for(b, payee, amount).save! if amount >= minimum
          end
          b
        end
        batch.recalculate_totals!
        batch
      end

      def payees(store)
        store.sellers.includes(:bank_account).to_a + store.partners.includes(:bank_account).to_a
      end

      # Payees that have money due but can't be paid yet (no verified bank account)
      def blocked_payees(store, minimum: Spree::PayoutBatch::MINIMUM_PAYOUT)
        payees(store).reject(&:payout_ready?).select { |p| p.available_balance >= minimum }
      end

      # -- internals -----------------------------------------------------------

      def record_sales(order)
        available_at = paid_at(order) + hold_days.days
        order.line_items.includes(:seller).each do |li|
          seller = li.seller
          next if seller.nil?

          gross = (li.price * li.quantity).to_d
          rate = seller.effective_commission_rate(order.completed_at)
          record(seller, kind: 'sale', amount: gross, key: "sale:#{li.id}", order: order, source: li,
                         available_at: available_at, description: "#{li.quantity} × #{li.name} — order #{order.number}")
          record(seller, kind: 'commission', amount: -(gross * rate / 100).round(2), key: "commission:#{li.id}",
                         order: order, source: li, available_at: available_at,
                         description: "#{rate.to_s('F')}% commission — order #{order.number}", metadata: { rate: rate.to_s('F') })
        end
      end

      # Each refund is shared across the order's line items in proportion to their value; the share that
      # falls on delivery stays with EcloudMall. Sellers give back the refunded amount less the commission on it.
      def record_refunds(order)
        order_total = order.total.to_d
        return if order_total.zero?

        order.refunds.each do |refund|
          order.line_items.includes(:seller).each do |li|
            seller = li.seller
            next if seller.nil?

            share = (refund.amount.to_d * (li.price * li.quantity).to_d / order_total).round(2)
            next if share.zero?

            rate = commission_rate_recorded(li) || seller.effective_commission_rate(order.completed_at)
            record(seller, kind: 'refund', amount: -share, key: "refund:#{refund.id}:#{li.id}", order: order, source: refund,
                           description: "Refund to customer — order #{order.number}")
            record(seller, kind: 'commission_reversal', amount: (share * rate / 100).round(2),
                           key: "commission_reversal:#{refund.id}:#{li.id}", order: order, source: refund,
                           description: "Commission returned on refund — order #{order.number}")
          end
        end
      end

      def commission_rate_recorded(line_item)
        entry = Spree::LedgerEntry.find_by(idempotency_key: "commission:#{line_item.id}")
        entry&.metadata&.dig('rate')&.to_d
      end

      def paid_at(order)
        order.payments.where(state: 'completed').maximum(:updated_at) || order.completed_at || Time.current
      end

      def record(payee, kind:, amount:, key:, order: nil, source: nil, available_at: Time.current, description: nil, metadata: nil)
        Spree::LedgerEntry.record!(
          idempotency_key: key, store: payee.store, payee: payee, kind: kind, amount: amount,
          currency: order&.currency || payee.store.default_currency, available_at: available_at,
          order: order, source: source, description: description&.truncate(250), metadata: metadata
        )
      end
    end
  end
end
