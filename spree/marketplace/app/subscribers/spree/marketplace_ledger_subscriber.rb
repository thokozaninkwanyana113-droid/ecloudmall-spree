module Spree
  # Keeps the marketplace ledger in step with payments and refunds.
  # Payout runs also re-sync recent orders, so a missed event never causes an underpayment.
  class MarketplaceLedgerSubscriber < Spree::Subscriber
    subscribes_to 'order.completed', 'payment.completed', 'refund.created'

    on 'order.completed', :sync_from_order
    on 'payment.completed', :sync_from_payment
    on 'refund.created', :sync_from_refund

    def sync_from_order(event)
      sync(Spree::Order.find_by_param(event.payload['id']))
    end

    def sync_from_payment(event)
      sync(Spree::Payment.find_by_param(event.payload['id'])&.order)
    end

    def sync_from_refund(event)
      sync(Spree::Refund.find_by_param(event.payload['id'])&.payment&.order)
    end

    private

    def sync(order)
      Spree::Marketplace::Ledger.sync_order!(order) if order
    end
  end
end
