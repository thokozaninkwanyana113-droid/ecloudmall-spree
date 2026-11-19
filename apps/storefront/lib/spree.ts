import 'server-only';
import { createClient, type Product } from '@spree/sdk';

export const SPREE_API_URL = process.env.SPREE_API_URL ?? 'http://localhost:3000';
export const SPREE_PUBLISHABLE_KEY = process.env.SPREE_PUBLISHABLE_KEY ?? '';

export const spree = createClient({
  baseUrl: SPREE_API_URL,
  publishableKey: SPREE_PUBLISHABLE_KEY,
  currency: 'ZAR',
  locale: 'en',
  country: 'ZA',
});

/** Compact seller object embedded in every product by the marketplace engine */
export interface SellerSummary {
  id: string;
  name: string;
  slug: string;
  tagline: string | null;
  province: string | null;
  province_name: string | null;
  city: string | null;
  location: string;
  brand_color: string | null;
  verified: boolean;
  badges: string[];
  logo_url: string | null;
  dispatch_days: number | null;
}

export type MarketProduct = Product & { seller_id: string | null; seller: SellerSummary | null };

export interface Seller extends SellerSummary {
  description: string | null;
  story_headline: string | null;
  story: string | null;
  township: string | null;
  business_type: string | null;
  business_type_name: string | null;
  primary_category: string | null;
  bbbee_level: number | null;
  black_owned: boolean;
  women_owned: boolean;
  youth_owned: boolean;
  disability_owned: boolean;
  township_business: boolean;
  featured: boolean;
  founded_year: number | null;
  team_size: number | null;
  ships_nationwide: boolean;
  offers_collection: boolean;
  website: string | null;
  instagram: string | null;
  facebook: string | null;
  tiktok: string | null;
  whatsapp: string | null;
  products_count: number;
  banner_url: string | null;
  approved_at: string | null;
}

export interface Paginated<T> {
  data: T[];
  meta: { page: number; limit: number; count: number; pages: number };
}

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public details?: Record<string, string[]>,
  ) {
    super(message);
  }
}

/** Minimal fetch helper for marketplace endpoints that are not part of @spree/sdk */
async function marketplaceRequest<T>(
  method: 'GET' | 'POST',
  path: string,
  { query, body }: { query?: Record<string, string | number | boolean | undefined>; body?: unknown } = {},
): Promise<T> {
  const url = new URL(`/api/v3/store${path}`, SPREE_API_URL);
  for (const [k, v] of Object.entries(query ?? {})) {
    if (v !== undefined && v !== '') url.searchParams.set(k, String(v));
  }
  const res = await fetch(url, {
    method,
    headers: {
      'x-spree-api-key': SPREE_PUBLISHABLE_KEY,
      'content-type': 'application/json',
      accept: 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
    cache: 'no-store',
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = json?.error ?? {};
    throw new ApiError(err.message ?? `Request failed (${res.status})`, res.status, err.details);
  }
  return json as T;
}

export const marketplace = {
  sellers: {
    list: (params: {
      page?: number;
      limit?: number;
      sort?: string;
      province?: string;
      impact?: string;
      featured?: boolean;
      search?: string;
    } = {}) =>
      marketplaceRequest<Paginated<Seller>>('GET', '/sellers', {
        query: {
          page: params.page,
          limit: params.limit ?? 24,
          sort: params.sort,
          'q[province_eq]': params.province,
          'q[featured_eq]': params.featured ? true : undefined,
          'q[name_cont]': params.search,
          ...(params.impact ? { [`q[${params.impact}_eq]`]: true } : {}),
        },
      }),
    get: (slug: string) => marketplaceRequest<Seller>('GET', `/sellers/${encodeURIComponent(slug)}`),
  },
  applications: {
    create: (body: Record<string, unknown>) =>
      marketplaceRequest<{ id: string; name: string; status: string; message: string }>(
        'POST',
        '/seller_applications',
        { body },
      ),
  },
};
