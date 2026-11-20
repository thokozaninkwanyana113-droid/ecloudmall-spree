export function Marquee({ items, className = 'bg-ink text-white' }: { items: string[]; className?: string }) {
  const row = [...items, ...items];
  return (
    <div className={`overflow-hidden border-b-2 border-ink py-2 text-sm font-bold ${className}`}>
      <div className="flex w-max animate-marquee gap-10 whitespace-nowrap">
        {row.map((t, i) => (
          <span key={i} className="flex items-center gap-10">
            {t}
            <span aria-hidden className="text-sun">✦</span>
          </span>
        ))}
      </div>
    </div>
  );
}
