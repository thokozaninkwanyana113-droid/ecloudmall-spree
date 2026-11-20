import Link from 'next/link';
import { Logo } from './Logo';
import { PROVINCES } from '@/lib/constants';

export function Footer() {
  return (
    <footer className="mt-24 border-t-2 border-ink bg-ink text-white">
      <div className="ndebele-band h-6 border-b-2 border-ink" />
      <div className="mx-auto grid max-w-7xl gap-10 px-4 py-14 md:grid-cols-4">
        <div className="space-y-4">
          <Logo className="text-white" />
          <p className="text-sm text-white/70">
            The marketplace built for South Africa’s small, medium and micro enterprises. Local makers, fair commission, real impact.
          </p>
          <p className="text-xs text-white/50">All prices in ZAR and include 15% VAT.</p>
        </div>
        <div>
          <h4 className="mb-3 font-display text-lg font-bold text-sun">Shop</h4>
          <ul className="space-y-2 text-sm text-white/80">
            <li><Link href="/shop">All products</Link></li>
            <li><Link href="/sellers">Meet the sellers</Link></li>
            <li><Link href="/shop?impact=women_owned">Women-owned</Link></li>
            <li><Link href="/shop?impact=township_business">Kasi made</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="mb-3 font-display text-lg font-bold text-sun">Provinces</h4>
          <ul className="grid grid-cols-2 gap-2 text-sm text-white/80">
            {PROVINCES.map((p) => (
              <li key={p.code}><Link href={`/shop?province=${p.code}`}>{p.name}</Link></li>
            ))}
          </ul>
        </div>
        <div>
          <h4 className="mb-3 font-display text-lg font-bold text-sun">Sell</h4>
          <ul className="space-y-2 text-sm text-white/80">
            <li><Link href="/sell">Become a seller</Link></li>
            <li><Link href="/sell#pricing">Fees & payouts</Link></li>
            <li><Link href="/account">My account</Link></li>
          </ul>
        </div>
      </div>
      <div className="border-t border-white/10 py-6 text-center text-xs text-white/50">
        © {new Date().getFullYear()} EcloudMall · Made with ❤️ in Mzansi · Powered by Spree Commerce
      </div>
    </footer>
  );
}
