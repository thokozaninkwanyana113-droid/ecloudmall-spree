import Link from 'next/link';
import type { Metadata } from 'next';
import { listProducts, getCategories, findCategory } from '@/lib/catalog';
import { PROVINCES, IMPACT_FILTERS, provinceName } from '@/lib/constants';
import { ProductCard } from '@/components/ProductCard';

export const dynamic = 'force-dynamic';

type SP = Promise<Record<string, string | undefined>>;

const SORTS = [
  { value: '', label: 'Featured' },
  { value: '-available_on', label: 'Newest' },
  { value: 'price', label: 'Price: low → high' },
  { value: '-price', label: 'Price: high → low' },
  { value: 'best_selling', label: 'Best selling' },
];

export async function generateMetadata({ searchParams }: { searchParams: SP }): Promise<Metadata> {
  const sp = await searchParams;
  const cat = await findCategory(sp.category);
  const parts = [cat?.name, sp.province && provinceName(sp.province), sp.q && `“${sp.q}”`].filter(Boolean);
  return { title: parts.length ? `Shop ${parts.join(' · ')}` : 'Shop all products' };
}

export default async function ShopPage({ searchParams }: { searchParams: SP }) {
  const sp = await searchParams;
  const page = Math.max(1, Number(sp.page ?? 1));
  const [result, categories, category] = await Promise.all([
    listProducts({ q: sp.q, category: sp.category, province: sp.province, impact: sp.impact, sort: sp.sort, page }),
    getCategories(),
    findCategory(sp.category),
  ]);

  const href = (patch: Record<string, string | undefined>) => {
    const next = new URLSearchParams();
    const merged = { ...sp, page: undefined, ...patch };
    for (const [k, v] of Object.entries(merged)) if (v) next.set(k, v);
    const qs = next.toString();
    return qs ? `/shop?${qs}` : '/shop';
  };

  const activeFilters = [
    sp.q && { label: `“${sp.q}”`, clear: { q: undefined } },
    category && { label: category.name, clear: { category: undefined } },
    sp.province && { label: provinceName(sp.province), clear: { province: undefined } },
    sp.impact && { label: IMPACT_FILTERS.find((f) => f.key === sp.impact)?.label ?? sp.impact, clear: { impact: undefined } },
  ].filter(Boolean) as { label: string; clear: Record<string, undefined> }[];

  const heading = category?.name ?? (sp.q ? `Results for “${sp.q}”` : sp.province ? `Made in ${provinceName(sp.province)}` : 'Shop everything local');

  return (
    <div className="mx-auto max-w-7xl px-4 py-10">
      <header className="mb-8 flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-sm font-black uppercase tracking-[0.2em] text-flame">{result.meta.count} products</p>
          <h1 className="font-display text-4xl font-extrabold tracking-tight md:text-6xl">{heading}</h1>
        </div>
        <div className="flex flex-wrap gap-2">
          {SORTS.map((s) => (
            <Link key={s.value} href={href({ sort: s.value || undefined })} className={`chip ${(sp.sort ?? '') === s.value ? 'chip-active' : ''}`}>
              {s.label}
            </Link>
          ))}
        </div>
      </header>

      <div className="grid gap-8 lg:grid-cols-[260px_1fr]">
        <aside className="space-y-6">
          <FilterGroup title="Category">
            <Link href={href({ category: undefined })} className={`chip ${!sp.category ? 'chip-active' : ''}`}>All</Link>
            {categories.map((c) => (
              <span key={c.id} className="contents">
                <Link href={href({ category: c.slug })} className={`chip ${sp.category === c.slug ? 'chip-active' : ''}`}>{c.name}</Link>
                {(sp.category === c.slug || c.children.some((ch) => ch.slug === sp.category)) &&
                  c.children.map((ch) => (
                    <Link key={ch.id} href={href({ category: ch.slug })} className={`chip ml-3 text-xs ${sp.category === ch.slug ? 'chip-active' : ''}`}>
                      ↳ {ch.name}
                    </Link>
                  ))}
              </span>
            ))}
          </FilterGroup>
          <FilterGroup title="Province">
            {PROVINCES.map((p) => (
              <Link key={p.code} href={href({ province: sp.province === p.code ? undefined : p.code })} className={`chip ${sp.province === p.code ? 'chip-active' : ''}`}>
                <span className="inline-block h-2.5 w-2.5 rounded-full border border-ink" style={{ background: p.color }} /> {p.name}
              </Link>
            ))}
          </FilterGroup>
          <FilterGroup title="Shop with impact">
            {IMPACT_FILTERS.map((f) => (
              <Link key={f.key} href={href({ impact: sp.impact === f.key ? undefined : f.key })} className={`chip ${sp.impact === f.key ? 'chip-active' : ''}`}>
                {f.emoji} {f.label}
              </Link>
            ))}
          </FilterGroup>
        </aside>

        <section>
          {activeFilters.length > 0 && (
            <div className="mb-6 flex flex-wrap items-center gap-2">
              {activeFilters.map((f) => (
                <Link key={f.label} href={href(f.clear)} className="chip bg-lime">
                  {f.label} ✕
                </Link>
              ))}
              <Link href="/shop" className="text-sm font-bold underline">Clear all</Link>
            </div>
          )}
          {result.data.length === 0 ? (
            <div className="card-pop rounded-3xl bg-white p-12 text-center">
              <p className="text-5xl">🤷🏾</p>
              <h2 className="mt-4 font-display text-2xl font-extrabold">Nothing here… yet</h2>
              <p className="mt-2 text-ink/70">Try another filter — or know a business that should be selling this? Tell them about EcloudMall.</p>
              <Link href="/shop" className="btn btn-primary mt-6">Reset filters</Link>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-4 md:gap-6 xl:grid-cols-3">
              {result.data.map((p, i) => (
                <ProductCard key={p.id} product={p} priority={i < 6} />
              ))}
            </div>
          )}
          {result.meta.pages > 1 && (
            <nav className="mt-10 flex justify-center gap-2" aria-label="Pagination">
              {Array.from({ length: result.meta.pages }, (_, i) => i + 1).map((n) => (
                <Link key={n} href={href({ page: n === 1 ? undefined : String(n) })} className={`chip ${n === page ? 'chip-active' : ''}`}>
                  {n}
                </Link>
              ))}
            </nav>
          )}
        </section>
      </div>
    </div>
  );
}

function FilterGroup({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="mb-3 font-display text-lg font-extrabold">{title}</h3>
      <div className="flex flex-wrap gap-2 lg:flex-col lg:items-start">{children}</div>
    </div>
  );
}
