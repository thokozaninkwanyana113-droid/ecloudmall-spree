export function rand(amount: string | number | null | undefined, opts: { cents?: boolean } = {}) {
  const n = Number(amount ?? 0);
  const showCents = opts.cents ?? !Number.isInteger(n);
  const formatted = n.toLocaleString('en-ZA', {
    minimumFractionDigits: showCents ? 2 : 0,
    maximumFractionDigits: showCents ? 2 : 0,
  });
  return `R${formatted.replace(/ /g, ' ')}`;
}

export function percentOff(price?: string | null, compare?: string | null) {
  const p = Number(price);
  const c = Number(compare);
  if (!c || !p || c <= p) return null;
  return Math.round(((c - p) / c) * 100);
}

/** Small deterministic hash used for generative product art */
export function hash(input: string) {
  let h = 2166136261;
  for (let i = 0; i < input.length; i++) {
    h ^= input.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

export function initials(name: string) {
  return name
    .split(/\s+/)
    .filter((w) => /[A-Za-z]/.test(w[0] ?? ''))
    .slice(0, 2)
    .map((w) => w[0]!.toUpperCase())
    .join('');
}

export function businessDaysFromNow(days: number) {
  const d = new Date();
  let added = 0;
  while (added < days) {
    d.setDate(d.getDate() + 1);
    const day = d.getDay();
    if (day !== 0 && day !== 6) added++;
  }
  return d.toLocaleDateString('en-ZA', { weekday: 'short', day: 'numeric', month: 'short' });
}
