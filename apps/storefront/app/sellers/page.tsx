import Link from 'next/link';
import type { Metadata } from 'next';
import { marketplace } from '@/lib/spree';
import { PROVINCES, IMPACT_FILTERS } from '@/lib/constants';
import { SellerCard } from '@/components/SellerCard';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Meet the sellers' };

type SP = Promise<Record<string, string | undefined>>;

export default async function SellersPage({ searchParams }: { searchParams: SP }) {
  const sp = await searchParams;
  const sellers = await marketplace.sellers.list({ province: sp.province, impact: sp.impact, search: sp.q, limit: 60 });
  const href = (patch: Record<string, string | undefined>) => {
    const next = new URLSearchParams();
    for (const [k, v] of Object.entries({ ...sp, ...patch })) if (v) next.set(k, v);
    const qs = next.toString();
    return qs ? `/sellers?${qs}` : '/sellers';
  };

  return (
    <div className="mx-auto max-w-7xl px-4 py-10">
      <header className="mb-10 grid gap-6 md:grid-cols-[1fr_auto] md:items-end">
        <div>
          <p className="text-sm font-black uppercase tracking-[0.2em] text-flame">{sellers.meta.count} verified local businesses</p>
          <h1 className="font-display text-5xl font-extrabold tracking-tight md:text-6xl">Meet the makers</h1>
          <p className="mt-3 max-w-2xl text-lg text-ink/70">
            Every seller on EcloudMall is a South African small business. Filter by province or by the impact you want your rands to make.
          </p>
        </div>
        <form action="/sellers" className="flex gap-2">
          <input name="q" defaultValue={sp.q} placeholder="Find a seller" className="field" />
          <button className="btn btn-dark">Go</button>
        </form>
      </header>
      <div className="mb-4 flex flex-wrap gap-2">
        <Link href={href({ province: undefined })} className={`chip ${!sp.province ? 'chip-active' : ''}`}>All provinces</Link>
        {PROVINCES.map((p) => (
          <Link key={p.code} href={href({ province: sp.province === p.code ? undefined : p.code })} className={`chip ${sp.province === p.code ? 'chip-active' : ''}`}>
            {p.name}
          </Link>
        ))}
      </div>
      <div className="mb-10 flex flex-wrap gap-2">
        {IMPACT_FILTERS.map((f) => (
          <Link key={f.key} href={href({ impact: sp.impact === f.key ? undefined : f.key })} className={`chip ${sp.impact === f.key ? 'chip-active' : ''}`}>
            {f.emoji} {f.label}
          </Link>
        ))}
      </div>
      {sellers.data.length === 0 ? (
        <div className="card-pop rounded-3xl bg-white p-12 text-center">
          <p className="text-5xl">🌱</p>
          <h2 className="mt-4 font-display text-2xl font-extrabold">No sellers match — yet.</h2>
          <p className="mt-2 text-ink/70">Run a business here? Be the first.</p>
          <Link href="/sell" className="btn btn-primary mt-6">Become a seller</Link>
        </div>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {sellers.data.map((v) => (
            <SellerCard key={v.id} seller={v} />
          ))}
        </div>
      )}
    </div>
  );
}
