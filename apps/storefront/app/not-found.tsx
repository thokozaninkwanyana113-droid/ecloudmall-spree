import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="mx-auto max-w-xl px-4 py-24 text-center">
      <p className="font-display text-9xl font-extrabold text-stroke">404</p>
      <h1 className="mt-4 font-display text-4xl font-extrabold">Eish, this page took a taxi somewhere else.</h1>
      <p className="mt-3 text-ink/70">It might have moved, or the seller is restocking.</p>
      <Link href="/" className="btn btn-primary mt-8">Take me home</Link>
    </div>
  );
}
