module HostedGatewayHelpers
  # An order sitting at the payment step, ready for a hosted payment session.
  def order_ready_for_payment(store)
    order = create(:order_with_line_items, store: store, line_items_count: 1)
    order.update_columns(state: 'payment', email: 'buyer@example.co.za')
    order.shipments.each { |s| s.update_column(:state, 'ready') }
    order.reload
  end
end

RSpec.configure { |c| c.include HostedGatewayHelpers }
