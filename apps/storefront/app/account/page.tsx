import Link from 'next/link';
import { redirect } from 'next/navigation';
import type { Metadata } from 'next';
import { spree } from '@/lib/spree';
import { getCustomer, getAuthToken } from '@/lib/session';
import { rand } from '@/lib/format';
import { logout } from '@/app/actions';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'My account' };

export default async function AccountPage({ searchParams }: { searchParams: Promise<{ welcome?: string }> }) {
  const [customer, token, { welcome }] = await Promise.all([getCustomer(), getAuthToken(), searchParams]);
  if (!customer || !token) redirect('/account/login');
  const orders = await spree.customer.orders.list({ limit: 20 }, { token }).catch(() => ({ data: [] }));

  return (
    <div className="mx-auto max-w-5xl px-4 py-12">
      {welcome && (
        <p className="mb-6 rounded-2xl border-2 border-ink bg-lime px-5 py-4 font-bold">🎉 Welcome to EcloudMall, {customer.first_name ?? 'friend'}! Your account is ready.</p>
      )}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-sm font-black uppercase tracking-[0.2em] text-flame">My account</p>
          <h1 className="font-display text-5xl font-extrabold tracking-tight">Sawubona, {customer.first_name ?? customer.email.split('@')[0]} 👋🏾</h1>
          <p className="text-ink/60">{customer.email}</p>
        </div>
        <form action={logout}><button className="btn btn-light">Log out</button></form>
      </div>
      <section className="mt-10">
        <h2 className="font-display text-3xl font-extrabold">Your orders</h2>
        {orders.data.length === 0 ? (
          <div className="card-pop mt-4 rounded-3xl bg-white p-8 text-center">
            <p className="text-lg">No orders yet.</p>
            <Link href="/shop" className="btn btn-primary mt-4">Find something lekker</Link>
          </div>
        ) : (
          <ul className="mt-4 space-y-3">
            {orders.data.map((o) => (
              <li key={o.id}>
                <Link href={`/orders/${o.id}`} className="card-pop flex flex-wrap items-center justify-between gap-4 rounded-3xl bg-white p-5">
                  <span>
                    <span className="block font-display text-xl font-extrabold">#{o.number}</span>
                    <span className="text-sm text-ink/60">{o.completed_at ? new Date(o.completed_at).toLocaleDateString('en-ZA', { dateStyle: 'medium' }) : ''} · {o.total_quantity} items</span>
                  </span>
                  <span className="chip">{o.fulfillment_status ?? 'processing'}</span>
                  <span className="font-display text-xl font-extrabold">{rand(o.total)}</span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
