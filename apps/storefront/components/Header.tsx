import Link from 'next/link';
import { getCart, getAuthToken } from '@/lib/session';
import { Logo } from './Logo';
import { Marquee } from './Marquee';

const NAV = [
  { href: '/shop', label: 'Shop' },
  { href: '/sellers', label: 'Sellers' },
  { href: '/shop?category=tech-and-load-shedding', label: '🔋 Load-shedding' },
  { href: '/shop?impact=township_business', label: 'Kasi Made' },
];

export async function Header() {
  const [cart, token] = await Promise.all([getCart(), getAuthToken()]);
  const count = cart?.total_quantity ?? 0;

  return (
    <header className="sticky top-0 z-40">
      <Marquee
        items={[
          '🇿🇦 100% South African SMMEs',
          '🚚 Free delivery over R750',
          '💳 Pay by Instant EFT or on delivery',
          '📦 Paxi & Pargo pickup from R59',
          '🤝 Every rand supports a local business',
          '✨ New sellers joining every week',
        ]}
      />
      <div className="border-b-2 border-ink bg-cream/95 backdrop-blur">
        <div className="mx-auto flex max-w-7xl items-center gap-4 px-4 py-3 md:gap-8">
          <Link href="/" aria-label="EcloudMall home">
            <Logo />
          </Link>
          <nav className="hidden items-center gap-1 lg:flex">
            {NAV.map((n) => (
              <Link key={n.href} href={n.href} className="rounded-full px-3 py-2 text-sm font-bold hover:bg-lime">
                {n.label}
              </Link>
            ))}
          </nav>
          <form action="/shop" className="ml-auto hidden flex-1 md:block md:max-w-sm">
            <label className="relative block">
              <span className="sr-only">Search</span>
              <input
                name="q"
                placeholder="Search vellies, marula oil, biltong…"
                className="w-full rounded-full border-2 border-ink bg-white py-2.5 pl-10 pr-4 text-sm outline-none focus:shadow-[3px_3px_0_#ffb612]"
              />
              <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2">🔍</span>
            </label>
          </form>
          <div className="ml-auto flex items-center gap-2 md:ml-0">
            <Link href="/sell" className="hidden rounded-full border-2 border-ink bg-ink px-4 py-2 text-sm font-bold text-white hover:bg-veld sm:block">
              Sell with us
            </Link>
            <Link href={token ? '/account' : '/account/login'} className="grid h-11 w-11 place-items-center rounded-full border-2 border-ink bg-white hover:bg-lime" aria-label="Account">
              👤
            </Link>
            <Link href="/cart" className="relative grid h-11 w-11 place-items-center rounded-full border-2 border-ink bg-sun hover:bg-lime" aria-label={`Cart, ${count} items`}>
              🛍️
              {count > 0 && (
                <span className="absolute -right-1.5 -top-1.5 grid h-6 min-w-6 place-items-center rounded-full border-2 border-ink bg-pink px-1 text-xs font-black">
                  {count}
                </span>
              )}
            </Link>
          </div>
        </div>
        <nav className="flex gap-1 overflow-x-auto px-4 pb-2 lg:hidden">
          {NAV.map((n) => (
            <Link key={n.href} href={n.href} className="chip shrink-0">
              {n.label}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}
