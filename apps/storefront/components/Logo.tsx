export function Logo({ className = '' }: { className?: string }) {
  return (
    <span className={`inline-flex items-center gap-2 font-display text-2xl font-extrabold tracking-tight ${className}`}>
      <span className="relative grid h-9 w-9 place-items-center rounded-xl border-2 border-ink bg-sun shadow-[3px_3px_0_#0b0b0f]">
        <svg viewBox="0 0 24 24" className="h-5 w-5" aria-hidden>
          <path d="M3 9 L12 3 L21 9 V20 H3Z" fill="#0b0b0f" />
          <path d="M8 20 V13 H16 V20" fill="#c6f432" />
          <circle cx="12" cy="9" r="2" fill="#ff4fa3" />
        </svg>
      </span>
      <span>
        ecloud<span className="text-veld">mall</span>
      </span>
    </span>
  );
}
