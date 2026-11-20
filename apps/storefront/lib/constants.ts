export const PROVINCES = [
  { code: 'GP', name: 'Gauteng', nickname: 'Place of Gold', color: '#FFB612' },
  { code: 'WC', name: 'Western Cape', nickname: 'Fairest Cape', color: '#2A9D8F' },
  { code: 'KZN', name: 'KwaZulu-Natal', nickname: 'Kingdom of the Zulu', color: '#DE3831' },
  { code: 'EC', name: 'Eastern Cape', nickname: 'Big Sky Country', color: '#8C5E3C' },
  { code: 'LP', name: 'Limpopo', nickname: 'Land of Legends', color: '#6A994E' },
  { code: 'MP', name: 'Mpumalanga', nickname: 'Place of the Rising Sun', color: '#F4A261' },
  { code: 'NW', name: 'North West', nickname: 'Platinum Province', color: '#9B5DE5' },
  { code: 'FS', name: 'Free State', nickname: 'Heartland', color: '#7F4F24' },
  { code: 'NC', name: 'Northern Cape', nickname: 'Land of Wide Open Spaces', color: '#D62828' },
] as const;

export type ProvinceCode = (typeof PROVINCES)[number]['code'];

export const provinceName = (code?: string | null) =>
  PROVINCES.find((p) => p.code === code)?.name ?? code ?? '';

/** Impact filters map to Ransack predicates on the seller association */
export const IMPACT_FILTERS = [
  { key: 'black_owned', label: 'Black-owned', emoji: '✊🏿' },
  { key: 'women_owned', label: 'Women-owned', emoji: '👩🏾‍💼' },
  { key: 'youth_owned', label: 'Youth-owned', emoji: '⚡' },
  { key: 'township_business', label: 'Township-made', emoji: '🏘️' },
] as const;

export type ImpactKey = (typeof IMPACT_FILTERS)[number]['key'];

export const BADGE_LABELS: Record<string, string> = {
  black_owned: 'Black-owned',
  women_owned: 'Women-owned',
  youth_owned: 'Youth-owned',
  disability_owned: 'Disability-owned',
  township_business: 'Township-made',
  verified: 'Verified seller',
};

export function badgeLabel(badge: string) {
  if (badge.startsWith('bbbee_level_')) return `B-BBEE Level ${badge.replace('bbbee_level_', '')}`;
  return BADGE_LABELS[badge] ?? badge;
}

export const CATEGORY_ORDER = [
  'Fashion & Accessories',
  'Beauty & Wellness',
  'Home & Décor',
  'Food & Pantry',
  'Tech & Load-shedding',
  'Kids & Baby',
  'Leather Goods',
];

export const CATEGORY_EMOJI: Record<string, string> = {
  'Fashion & Accessories': '👗',
  'Beauty & Wellness': '🌿',
  'Home & Décor': '🏺',
  'Food & Pantry': '🌶️',
  'Tech & Load-shedding': '🔋',
  'Kids & Baby': '🧸',
  'Leather Goods': '👞',
};

export const FREE_DELIVERY_THRESHOLD = 750;
export const COMMISSION_RATE = 7.5;
