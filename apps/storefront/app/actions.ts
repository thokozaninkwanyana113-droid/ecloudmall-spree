'use server';

import { revalidatePath } from 'next/cache';
import { headers } from 'next/headers';
import { redirect } from 'next/navigation';
import { SpreeError } from '@spree/sdk';
import { spree, marketplace, ApiError } from '@/lib/spree';
import {
  cartOptions,
  getOrCreateCart,
  getCart,
  clearCartRef,
  setAuth,
  clearAuth,
  getAuthToken,
  getCartRef,
  rememberOrder,
  setPendingPayment,
} from '@/lib/session';

export type ActionState = { ok?: boolean; error?: string; fieldErrors?: Record<string, string[]>; message?: string };

export type HostedRedirect = { method: 'GET' | 'POST'; url: string; fields: Record<string, string> };
export type PaymentState = ActionState & { redirect?: HostedRedirect };

async function siteOrigin() {
  if (process.env.NEXT_PUBLIC_SITE_URL) return process.env.NEXT_PUBLIC_SITE_URL.replace(/\/$/, '');
  const h = await headers();
  return `${h.get('x-forwarded-proto') ?? 'http'}://${h.get('host')}`;
}

function errorMessage(e: unknown) {
  if (e instanceof SpreeError || e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return 'Something went wrong. Please try again.';
}

// ---------------------------------------------------------------- Cart

export async function addToCart(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const variantId = String(formData.get('variant_id') ?? '');
  const quantity = Math.max(1, Number(formData.get('quantity') ?? 1));
  try {
    const cart = await getOrCreateCart();
    await spree.carts.items.create(cart.id, { variant_id: variantId, quantity }, await cartOptions());
  } catch (e) {
    return { error: errorMessage(e) };
  }
  revalidatePath('/', 'layout');
  if (formData.get('buy_now')) redirect('/checkout');
  return { ok: true, message: 'Added to your cart' };
}

export async function updateItem(formData: FormData) {
  const cart = await getCart();
  if (!cart) return;
  const itemId = String(formData.get('item_id'));
  const quantity = Number(formData.get('quantity'));
  if (quantity <= 0) {
    await spree.carts.items.delete(cart.id, itemId, await cartOptions());
  } else {
    await spree.carts.items.update(cart.id, itemId, { quantity }, await cartOptions());
  }
  revalidatePath('/', 'layout');
}

export async function removeItem(formData: FormData) {
  const cart = await getCart();
  if (!cart) return;
  await spree.carts.items.delete(cart.id, String(formData.get('item_id')), await cartOptions());
  revalidatePath('/', 'layout');
}

export async function applyCoupon(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const cart = await getCart();
  if (!cart) return { error: 'Your cart is empty' };
  try {
    await spree.carts.discountCodes.apply(cart.id, String(formData.get('code') ?? '').trim(), await cartOptions());
  } catch (e) {
    return { error: errorMessage(e) };
  }
  revalidatePath('/', 'layout');
  return { ok: true, message: 'Discount applied 🎉' };
}

// ---------------------------------------------------------------- Checkout

export async function saveAddress(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const cart = await getCart();
  if (!cart) return { error: 'Your cart has expired — please add items again.' };
  const get = (k: string) => String(formData.get(k) ?? '').trim();
  try {
    await spree.carts.update(
      cart.id,
      {
        email: get('email'),
        customer_note: get('customer_note') || undefined,
        shipping_address: {
          first_name: get('first_name'),
          last_name: get('last_name'),
          address1: get('address1'),
          address2: get('address2') || undefined,
          city: get('city'),
          postal_code: get('postal_code'),
          phone: get('phone'),
          country_iso: 'ZA',
          state_abbr: get('state_abbr'),
        },
        use_shipping: true,
      },
      await cartOptions(),
    );
  } catch (e) {
    if (e instanceof SpreeError) return { error: e.message, fieldErrors: (e.details as Record<string, string[]>) ?? undefined };
    return { error: errorMessage(e) };
  }
  revalidatePath('/checkout');
  return { ok: true };
}

export async function selectDelivery(formData: FormData) {
  const cart = await getCart();
  if (!cart) return;
  await spree.carts.fulfillments.update(
    cart.id,
    String(formData.get('fulfillment_id')),
    { selected_delivery_rate_id: String(formData.get('rate_id')) },
    await cartOptions(),
  );
  revalidatePath('/checkout');
}

export async function selectPickupPoint(formData: FormData) {
  const cart = await getCart();
  const ref = await getCartRef();
  if (!cart || !ref) return;
  await marketplace.pickupPoints.select(
    cart.id,
    String(formData.get('fulfillment_id')),
    String(formData.get('pickup_point_id')),
    await cartOptions(),
  );
  revalidatePath('/checkout');
}

/** Starts a PayFast / Ozow / Yoco payment and returns the hosted-page redirect for the browser */
async function startHostedPayment(cartId: string, paymentMethodId: string): Promise<PaymentState> {
  const origin = await siteOrigin();
  const ref = await getCartRef();
  try {
    const session = await spree.carts.paymentSessions.create(
      cartId,
      {
        payment_method_id: paymentMethodId,
        external_data: { return_url: `${origin}/checkout/payment/return`, cancel_url: `${origin}/checkout/payment/return` },
      },
      await cartOptions(),
    );
    const redirect = (session.external_data as { redirect?: HostedRedirect }).redirect;
    if (!redirect) return { error: 'The payment provider did not respond. Please try another payment method.' };
    if (ref) await setPendingPayment({ sessionId: session.id, orderId: session.order_id, cartId: ref.id, cartToken: ref.token });
    return { ok: true, redirect };
  } catch (e) {
    return { error: errorMessage(e) };
  }
}

export async function placeOrder(_prev: PaymentState, formData: FormData): Promise<PaymentState> {
  const cart = await getCart();
  if (!cart) return { error: 'Your cart has expired — please add items again.' };
  const paymentMethodId = String(formData.get('payment_method_id') ?? '');
  if (!paymentMethodId) return { error: 'Choose how you would like to pay.' };
  const method = cart.payment_methods.find((m) => m.id === paymentMethodId);
  if (method?.session_required) return startHostedPayment(cart.id, paymentMethodId);
  let orderId: string;
  try {
    const opts = await cartOptions();
    if (!cart.payments.some((p) => p.status !== 'invalid' && p.status !== 'void')) {
      await spree.carts.payments.create(cart.id, { payment_method_id: paymentMethodId }, opts);
    }
    const order = await spree.carts.complete(cart.id, opts);
    orderId = order.id;
    const ref = await getCartRef();
    if (ref) await rememberOrder(order.id, ref.token);
    await clearCartRef();
  } catch (e) {
    return { error: errorMessage(e) };
  }
  revalidatePath('/', 'layout');
  redirect(`/orders/${orderId}?placed=1`);
}

// ---------------------------------------------------------------- Accounts

export async function login(_prev: ActionState, formData: FormData): Promise<ActionState> {
  try {
    const tokens = await spree.auth.login({
      email: String(formData.get('email') ?? ''),
      password: String(formData.get('password') ?? ''),
    });
    await setAuth(tokens);
    await attachGuestCart(tokens.token);
  } catch (e) {
    return { error: e instanceof SpreeError && e.status === 401 ? 'Incorrect email or password.' : errorMessage(e) };
  }
  revalidatePath('/', 'layout');
  redirect(String(formData.get('redirect_to') || '/account'));
}

export async function register(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const password = String(formData.get('password') ?? '');
  try {
    const tokens = await spree.customers.create({
      email: String(formData.get('email') ?? ''),
      first_name: String(formData.get('first_name') ?? ''),
      last_name: String(formData.get('last_name') ?? ''),
      phone: String(formData.get('phone') ?? '') || undefined,
      password,
      password_confirmation: password,
      accepts_email_marketing: formData.get('marketing') === 'on',
    });
    await setAuth(tokens);
    await attachGuestCart(tokens.token);
  } catch (e) {
    if (e instanceof SpreeError) return { error: e.message, fieldErrors: e.details as Record<string, string[]> };
    return { error: errorMessage(e) };
  }
  revalidatePath('/', 'layout');
  redirect('/account?welcome=1');
}

async function attachGuestCart(token: string) {
  const ref = await getCartRef();
  if (!ref) return;
  try {
    await spree.carts.associate(ref.id, { token, spreeToken: ref.token });
  } catch {
    // cart may already belong to someone else or be completed — ignore
  }
}

export async function logout() {
  await clearAuth();
  await clearCartRef();
  revalidatePath('/', 'layout');
  redirect('/');
}

export async function isLoggedIn() {
  return Boolean(await getAuthToken());
}

// ---------------------------------------------------------------- Sell on EcloudMall

export async function applyToSell(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const str = (k: string) => {
    const v = String(formData.get(k) ?? '').trim();
    return v === '' ? undefined : v;
  };
  const bool = (k: string) => formData.get(k) === 'on';
  if (!formData.get('consent')) return { error: 'Please accept the seller terms to continue.' };
  try {
    const res = await marketplace.applications.create({
      name: str('name'),
      tagline: str('tagline'),
      description: str('description'),
      contact_name: str('contact_name'),
      email: str('email'),
      phone: str('phone'),
      whatsapp: str('whatsapp'),
      website: str('website'),
      instagram: str('instagram'),
      province: str('province'),
      city: str('city'),
      township: str('township'),
      business_type: str('business_type'),
      registration_number: str('registration_number'),
      vat_number: str('vat_number'),
      bbbee_level: str('bbbee_level') ? Number(str('bbbee_level')) : undefined,
      primary_category: str('primary_category'),
      founded_year: str('founded_year') ? Number(str('founded_year')) : undefined,
      team_size: str('team_size') ? Number(str('team_size')) : undefined,
      black_owned: bool('black_owned'),
      women_owned: bool('women_owned'),
      youth_owned: bool('youth_owned'),
      disability_owned: bool('disability_owned'),
      township_business: bool('township_business'),
      offers_collection: bool('offers_collection'),
      referral_code: str('referral_code'),
    });
    return { ok: true, message: res.message };
  } catch (e) {
    if (e instanceof ApiError) return { error: e.message, fieldErrors: e.details };
    return { error: errorMessage(e) };
  }
}
