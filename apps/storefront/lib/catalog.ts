import 'server-only';
import { cache } from 'react';
import type { Category } from '@spree/sdk';
import { spree, type MarketProduct } from './spree';
import { CATEGORY_ORDER } from './constants';

export type CategoryNode = Omit<Category, 'children'> & { slug: string; children: CategoryNode[] };

export const getCategories = cache(async (): Promise<CategoryNode[]> => {
  const res = await spree.categories.list({ limit: 100 });
  const nodes = new Map<string, CategoryNode>();
  for (const c of res.data) {
    nodes.set(c.id, { ...c, slug: c.permalink.split('/').pop() ?? c.permalink, children: [] });
  }
  const roots: CategoryNode[] = [];
  for (const node of nodes.values()) {
    if (node.depth === 1) roots.push(node);
    else if (node.parent_id && nodes.has(node.parent_id) && node.depth > 1) nodes.get(node.parent_id)!.children.push(node);
  }
  const rank = (n: string) => {
    const i = CATEGORY_ORDER.indexOf(n);
    return i === -1 ? 99 : i;
  };
  roots.sort((a, b) => rank(a.name) - rank(b.name));
  roots.forEach((r) => r.children.sort((a, b) => a.name.localeCompare(b.name)));
  return roots;
});

export async function findCategory(slug?: string) {
  if (!slug) return null;
  const roots = await getCategories();
  for (const r of roots) {
    if (r.slug === slug) return r;
    const child = r.children.find((c) => c.slug === slug);
    if (child) return child;
  }
  return null;
}

export interface ProductQuery {
  q?: string;
  category?: string;
  province?: string;
  impact?: string;
  seller?: string;
  sort?: string;
  page?: number;
  limit?: number;
  maxPrice?: number;
}

export async function listProducts(query: ProductQuery) {
  const category = await findCategory(query.category);
  const params: Record<string, string | number | boolean | undefined> = {
    page: query.page ?? 1,
    limit: query.limit ?? 24,
    sort: query.sort || undefined,
    search: query.q || undefined,
    in_category: category?.id,
    seller_province_eq: query.province || undefined,
    seller_slug_eq: query.seller || undefined,
    price_lte: query.maxPrice || undefined,
  };
  if (query.impact) params[`seller_${query.impact}_eq`] = true;
  const res = await spree.products.list(params);
  return res as unknown as { data: MarketProduct[]; meta: { page: number; pages: number; count: number } };
}
