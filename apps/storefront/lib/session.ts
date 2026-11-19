import 'server-only';
import { cookies } from 'next/headers';
import type { Cart, Customer } from '@spree/sdk';
import { spree } from './spree';

const CART_COOKIE = 'ecm_cart';
const AUTH_COOKIE = 'ecm_auth';
const ORDER_COOKIE = 'ecm_orders';

const cookieOptions = {
  httpOnly: true,
  sameSite: 'lax' as const,
  secure: process.env.NODE_ENV === 'production',
  path: '/',
};

type CartRef = { id: string; token: string };

export async function getCartRef(): Promise<CartRef | null> {
  const raw = (await cookies()).get(CART_COOKIE)?.value;
  if (!raw) return null;
  try {
    return JSON.parse(raw) as CartRef;
  } catch {
    return null;
  }
}

export async function setCartRef(cart: { id: string; token: string }) {
  (await cookies()).set(CART_COOKIE, JSON.stringify({ id: cart.id, token: cart.token }), {
    ...cookieOptions,
    maxAge: 60 * 60 * 24 * 30,
  });
}

export async function clearCartRef() {
  (await cookies()).delete(CART_COOKIE);
}

export async function getAuthToken() {
  return (await cookies()).get(AUTH_COOKIE)?.value ?? null;
}

export async function setAuth(tokens: { token: string; refresh_token: string }) {
  (await cookies()).set(AUTH_COOKIE, tokens.token, { ...cookieOptions, maxAge: 60 * 60 * 24 * 7 });
}

export async function clearAuth() {
  (await cookies()).delete(AUTH_COOKIE);
}

/** Request options granting access to the current guest cart and/or customer */
export async function cartOptions() {
  const ref = await getCartRef();
  const token = await getAuthToken();
  return {
    ...(ref ? { spreeToken: ref.token } : {}),
    ...(token ? { token } : {}),
  };
}

export async function getCart(): Promise<Cart | null> {
  const ref = await getCartRef();
  if (!ref) return null;
  try {
    const cart = await spree.carts.get(ref.id, await cartOptions());
    return cart;
  } catch {
    return null;
  }
}

/** Returns the current cart or creates a new one (and stores it in a cookie) */
export async function getOrCreateCart(): Promise<Cart> {
  const existing = await getCart();
  if (existing) return existing;
  const token = await getAuthToken();
  const cart = await spree.carts.create({}, token ? { token } : undefined);
  await setCartRef(cart);
  return cart;
}

export async function getCustomer(): Promise<Customer | null> {
  const token = await getAuthToken();
  if (!token) return null;
  try {
    return await spree.customer.get({ token });
  } catch {
    return null;
  }
}

/** Remember guest order tokens so the confirmation page can load the order */
export async function rememberOrder(orderId: string, token: string) {
  const jar = await cookies();
  let map: Record<string, string> = {};
  try {
    map = JSON.parse(jar.get(ORDER_COOKIE)?.value ?? '{}');
  } catch {}
  const entries = Object.entries({ ...map, [orderId]: token }).slice(-5);
  jar.set(ORDER_COOKIE, JSON.stringify(Object.fromEntries(entries)), {
    ...cookieOptions,
    maxAge: 60 * 60 * 24 * 30,
  });
}

export async function orderToken(orderId: string) {
  try {
    return (JSON.parse((await cookies()).get(ORDER_COOKIE)?.value ?? '{}') as Record<string, string>)[orderId] ?? null;
  } catch {
    return null;
  }
}
