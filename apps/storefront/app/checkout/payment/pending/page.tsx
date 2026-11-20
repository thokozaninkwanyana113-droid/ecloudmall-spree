import Link from 'next/link';
import type { Metadata } from 'next';

export const metadata: Metadata = { title: 'Confirming your payment', robots: { index: false } };

export default async function PaymentPendingPage({ searchParams }: { searchParams: Promise<{ attempt?: string; stalled?: string }> }) {
  const { attempt = '1', stalled } = await searchParams;
  return (
    <div className="mx-auto max-w-xl px-4 py-24 text-center">
      {!stalled && <meta httpEquiv="refresh" content={`3;url=/checkout/payment/return?attempt=${attempt}`} />}
      <p className="text-7xl">{stalled ? '⏳' : '🔐'}</p>
      <h1 className="mt-6 font-display text-4xl font-extrabold">
        {stalled ? 'Still waiting for your bank…' : 'Confirming your payment…'}
      </h1>
      <p className="mt-3 text-lg text-ink/70">
        {stalled
          ? 'Your payment provider hasn’t confirmed yet. If money left your account, your order will be confirmed automatically and emailed to you — you don’t need to pay again.'
          : 'Hang tight — we’re waiting for the payment provider to confirm. This usually takes a few seconds.'}
      </p>
      {!stalled && (
        <div className="mx-auto mt-8 h-3 w-64 overflow-hidden rounded-full border-2 border-ink bg-white">
          <div className="h-full w-1/2 animate-[marquee_1.2s_linear_infinite] bg-veld" />
        </div>
      )}
      <div className="mt-10 flex justify-center gap-3">
        <Link href="/checkout/payment/return" className="btn btn-dark">Check again</Link>
        <Link href="/checkout" className="btn btn-light">Back to checkout</Link>
      </div>
    </div>
  );
}
