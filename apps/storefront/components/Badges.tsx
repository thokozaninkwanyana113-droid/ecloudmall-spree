import { badgeLabel } from '@/lib/constants';

const STYLES: Record<string, string> = {
  black_owned: 'bg-ink text-sun',
  women_owned: 'bg-pink text-ink',
  youth_owned: 'bg-lime text-ink',
  township_business: 'bg-sun text-ink',
  disability_owned: 'bg-ocean text-white',
  verified: 'bg-veld text-white',
};

export function Badges({ badges, max, size = 'sm' }: { badges: string[]; max?: number; size?: 'sm' | 'md' }) {
  const list = max ? badges.slice(0, max) : badges;
  return (
    <ul className="flex flex-wrap gap-1.5">
      {list.map((b) => (
        <li
          key={b}
          className={`rounded-full border-2 border-ink font-bold ${size === 'md' ? 'px-3 py-1 text-xs' : 'px-2 py-0.5 text-[10px]'} uppercase tracking-wide ${STYLES[b] ?? 'bg-white text-ink'}`}
        >
          {b === 'verified' ? '✓ ' : ''}
          {badgeLabel(b)}
        </li>
      ))}
    </ul>
  );
}
