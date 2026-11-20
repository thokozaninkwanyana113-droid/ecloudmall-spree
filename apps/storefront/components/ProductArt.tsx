import { hash } from '@/lib/format';

const PALETTES = [
  ['#FFB612', '#0B0B0F', '#DE3831', '#FFF8EC'],
  ['#007A4D', '#FFB612', '#0B0B0F', '#FFF8EC'],
  ['#002395', '#FF4FA3', '#FFB612', '#FFF8EC'],
  ['#DE3831', '#FFF8EC', '#0B0B0F', '#FFB612'],
  ['#C6F432', '#0B0B0F', '#FF4FA3', '#FFF8EC'],
  ['#9B5DE5', '#FFB612', '#0B0B0F', '#FFF8EC'],
];

/**
 * Generative, Ndebele-inspired artwork used when a seller hasn't uploaded a photo yet.
 * Deterministic per product so the same product always looks the same.
 */
export function ProductArt({
  name,
  accent,
  label,
  className = '',
}: {
  name: string;
  accent?: string | null;
  label?: string;
  className?: string;
}) {
  const h = hash(name);
  const base = PALETTES[h % PALETTES.length]!;
  const [c1, c2, c3, c4] = accent ? [accent, base[1]!, base[2]!, base[3]!] : base;
  const variant = (h >>> 3) % 4;
  const id = `art-${h.toString(36)}`;
  // Wrap the product name onto at most 3 lines of ~14 characters
  const lines: string[] = [];
  for (const word of name.split(' ')) {
    const last = lines[lines.length - 1];
    if (last !== undefined && (last + ' ' + word).length <= 14) lines[lines.length - 1] = `${last} ${word}`;
    else lines.push(word);
  }
  const shown = lines.slice(0, 3);
  const longest = Math.max(...shown.map((l) => l.length));
  const fontSize = Math.min(34, Math.floor(270 / Math.max(longest, 1) / 0.58));
  const lineHeight = fontSize * 1.1;
  const blockHeight = shown.length * lineHeight + (label ? 26 : 0);
  const startY = 194 - blockHeight / 2 + fontSize * 0.8;

  return (
    <svg
      viewBox="0 0 400 400"
      role="img"
      aria-label={name}
      className={className}
      preserveAspectRatio="xMidYMid slice"
    >
      <defs>
        <pattern id={`${id}-p`} width="80" height="80" patternUnits="userSpaceOnUse">
          {variant === 0 && (
            <>
              <rect width="80" height="80" fill={c1} />
              <path d="M0 40 L40 0 L80 40 L40 80Z" fill={c4} stroke={c2} strokeWidth="6" />
              <rect x="30" y="30" width="20" height="20" fill={c3} />
            </>
          )}
          {variant === 1 && (
            <>
              <rect width="80" height="80" fill={c1} />
              <rect x="0" y="0" width="40" height="40" fill={c4} stroke={c2} strokeWidth="5" />
              <rect x="40" y="40" width="40" height="40" fill={c3} stroke={c2} strokeWidth="5" />
            </>
          )}
          {variant === 2 && (
            <>
              <rect width="80" height="80" fill={c4} />
              <path d="M0 80 L40 20 L80 80Z" fill={c1} stroke={c2} strokeWidth="5" />
              <circle cx="40" cy="62" r="8" fill={c3} />
            </>
          )}
          {variant === 3 && (
            <>
              <rect width="80" height="80" fill={c1} />
              <path d="M0 0 H80 V20 H0Z M0 40 H80 V60 H0Z" fill={c4} />
              <path d="M10 20 L30 40 L50 20 L70 40" fill="none" stroke={c2} strokeWidth="6" />
            </>
          )}
        </pattern>
      </defs>
      <rect width="400" height="400" fill={`url(#${id}-p)`} />
      <g transform={`rotate(${(h % 9) - 4} 200 200)`}>
        <rect x="46" y="124" width="308" height="152" rx="18" fill="#0B0B0F" />
        <rect x="40" y="118" width="308" height="152" rx="18" fill="#FFF8EC" stroke="#0B0B0F" strokeWidth="5" />
        <text
          x="194"
          textAnchor="middle"
          fontFamily="var(--font-display), system-ui, sans-serif"
          fontWeight="800"
          fontSize={fontSize}
          fill="#0B0B0F"
        >
          {shown.map((line, i) => (
            <tspan key={i} x="194" y={startY + i * lineHeight}>
              {line}
            </tspan>
          ))}
        </text>
        {label && (
          <text
            x="194"
            y={startY + shown.length * lineHeight + 4}
            textAnchor="middle"
            fontFamily="var(--font-body), system-ui, sans-serif"
            fontWeight="600"
            fontSize="16"
            letterSpacing="2"
            fill="#0B0B0F"
            opacity="0.7"
          >
            {label.toUpperCase()}
          </text>
        )}
      </g>
    </svg>
  );
}
