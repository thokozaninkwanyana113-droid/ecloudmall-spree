import { NextResponse, type NextRequest } from 'next/server';
import { spree } from '@/lib/spree';
import {
  getPendingPayment,
  clearPendingPayment,
  clearCartRef,
  rememberOrder,
  getAuthToken,
} from '@/lib/session';

const OUR_PARAMS = new Set(['payment_session', 'result', 'attempt']);
const MAX_ATTEMPTS = 20;

/**
 * Shoppers land here after paying on PayFast / Ozow / Yoco.
 * We ask the backend to verify the payment (Ozow return hash, Yoco server lookup) — PayFast is
 * settled by its ITN — then send the shopper to their order, a waiting page, or back to checkout.
 */
export async function GET(request: NextRequest) {
  const url = request.nextUrl;
  const sp = url.searchParams;
  const pending = await getPendingPayment();
  const to = (path: string) => NextResponse.redirect(new URL(path, url.origin), 303);

  if (!pending) return to('/cart');

  const sessionId = sp.get('payment_session') ?? pending.sessionId;
  if (sessionId !== pending.sessionId) return to('/checkout?payment=failed');

  const result = sp.get('result') ?? 'success';
  const attempt = Number(sp.get('attempt') ?? 0);
  const providerFields = Object.fromEntries([...sp.entries()].filter(([k]) => !OUR_PARAMS.has(k)));
  const token = await getAuthToken();
  const auth = { spreeToken: pending.cartToken, ...(token ? { token } : {}) };

  let status: string | null = null;
  try {
    const session = await spree.carts.paymentSessions.complete(
      pending.cartId,
      sessionId,
      { session_result: result, external_data: providerFields },
      auth,
    );
    status = session.status;
  } catch {
    // The cart may already have been completed by the provider's webhook — check the order below.
  }

  let orderComplete = false;
  try {
    const order = await spree.orders.get(pending.orderId, undefined, auth);
    orderComplete = Boolean(order.completed_at);
  } catch {
    orderComplete = false;
  }

  if (orderComplete || status === 'completed') {
    await rememberOrder(pending.orderId, pending.cartToken);
    await clearCartRef();
    await clearPendingPayment();
    return to(`/orders/${pending.orderId}?placed=1`);
  }

  if (status === 'failed' || status === 'canceled' || status === 'expired' || result === 'canceled' || result === 'error') {
    await clearPendingPayment();
    return to(`/checkout?payment=${result === 'canceled' || status === 'canceled' ? 'canceled' : 'failed'}`);
  }

  if (attempt >= MAX_ATTEMPTS) return to('/checkout/payment/pending?stalled=1');
  return to(`/checkout/payment/pending?attempt=${attempt + 1}`);
}
