import { describe, expect, it } from 'vitest';
import { rand, percentOff, hash, initials } from '../lib/format';
import { badgeLabel, provinceName } from '../lib/constants';

describe('rand', () => {
  it('formats whole rands without cents and with SA thousand separators', () => {
    expect(rand('899.0')).toBe('R899');
    expect(rand(1299)).toBe('R1 299');
  });
  it('keeps cents when present or requested', () => {
    expect(rand('154.96')).toBe('R154,96');
    expect(rand(1188, { cents: true })).toBe('R1 188,00');
  });
});

describe('percentOff', () => {
  it('computes the discount against compare-at price', () => {
    expect(percentOff('899', '1099')).toBe(18);
    expect(percentOff('100', null)).toBeNull();
    expect(percentOff('100', '90')).toBeNull();
  });
});

describe('helpers', () => {
  it('hash is deterministic and unsigned', () => {
    expect(hash('Shweshwe Wrap Dress')).toBe(hash('Shweshwe Wrap Dress'));
    expect(hash('Marula Oil Face Serum')).toBeGreaterThanOrEqual(0);
  });
  it('builds initials from words', () => {
    expect(initials('Kasi Glow Naturals')).toBe('KG');
  });
  it('labels badges and provinces', () => {
    expect(badgeLabel('bbbee_level_2')).toBe('B-BBEE Level 2');
    expect(badgeLabel('township_business')).toBe('Township-made');
    expect(provinceName('KZN')).toBe('KwaZulu-Natal');
  });
});
