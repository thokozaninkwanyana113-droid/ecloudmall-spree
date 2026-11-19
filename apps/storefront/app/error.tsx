'use client';

export default function Error({ reset }: { error: Error; reset: () => void }) {
  return (
    <div className="mx-auto max-w-xl px-4 py-24 text-center">
      <p className="text-7xl">⚡</p>
      <h1 className="mt-4 font-display text-4xl font-extrabold">Something tripped — maybe load-shedding?</h1>
      <p className="mt-3 text-ink/70">We couldn’t reach the marketplace just now. Please try again.</p>
      <button onClick={reset} className="btn btn-primary mt-8">Try again</button>
    </div>
  );
}
