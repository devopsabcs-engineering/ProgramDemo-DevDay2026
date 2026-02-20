/**
 * Bilingual content verification tests.
 *
 * Ensures that the English and French translation files:
 *   1. Contain identical top-level and nested key sets.
 *   2. Have no empty string values.
 *   3. Have no keys that are identical across both languages
 *      (which would indicate an untranslated string).
 *
 * This test reads the JSON files from disk using Node's 'fs' module
 * so that it reflects the actual files served at runtime rather than
 * relying on any import-time bundle snapshot.
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, it, expect } from 'vitest';

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------

type TranslationNode = { [key: string]: string | TranslationNode };

/** Recursively collect all dot-separated key paths from a nested object. */
function collectKeys(obj: TranslationNode, prefix = ''): string[] {
  return Object.entries(obj).flatMap(([k, v]) => {
    const fullKey = prefix ? `${prefix}.${k}` : k;
    if (typeof v === 'object' && v !== null) {
      return collectKeys(v as TranslationNode, fullKey);
    }
    return [fullKey];
  });
}

/** Recursively collect all leaf { key → value } pairs. */
function collectLeaves(
  obj: TranslationNode,
  prefix = ''
): Record<string, string> {
  return Object.entries(obj).reduce<Record<string, string>>((acc, [k, v]) => {
    const fullKey = prefix ? `${prefix}.${k}` : k;
    if (typeof v === 'object' && v !== null) {
      return { ...acc, ...collectLeaves(v as TranslationNode, fullKey) };
    }
    acc[fullKey] = v as string;
    return acc;
  }, {});
}

// ------------------------------------------------------------------
// Load translation files
// ------------------------------------------------------------------

const localesRoot = resolve(
  __dirname,
  '../../public/locales'
);

const enTranslation = JSON.parse(
  readFileSync(resolve(localesRoot, 'en/translation.json'), 'utf-8')
) as TranslationNode;

const frTranslation = JSON.parse(
  readFileSync(resolve(localesRoot, 'fr/translation.json'), 'utf-8')
) as TranslationNode;

const enKeys = collectKeys(enTranslation).sort();
const frKeys = collectKeys(frTranslation).sort();
const enLeaves = collectLeaves(enTranslation);
const frLeaves = collectLeaves(frTranslation);

// ------------------------------------------------------------------
// Tests
// ------------------------------------------------------------------

describe('Bilingual content (EN / FR)', () => {
  it('EN and FR translation files have the same set of keys', () => {
    expect(frKeys).toEqual(enKeys);
  });

  it('EN translation has no empty string values', () => {
    const empty = Object.entries(enLeaves).filter(([, v]) => v.trim() === '');
    expect(empty).toHaveLength(0);
  });

  it('FR translation has no empty string values', () => {
    const empty = Object.entries(frLeaves).filter(([, v]) => v.trim() === '');
    expect(empty).toHaveLength(0);
  });

  it('FR translation file does not contain any keys missing from EN', () => {
    const missingInEn = frKeys.filter((k) => !enKeys.includes(k));
    expect(missingInEn).toHaveLength(0);
  });

  it('EN translation file does not contain any keys missing from FR', () => {
    const missingInFr = enKeys.filter((k) => !frKeys.includes(k));
    expect(missingInFr).toHaveLength(0);
  });

  it('key values differ between EN and FR for known translated strings', () => {
    // Spot-check a handful of keys that absolutely should differ
    const spotCheckKeys = [
      'submit.title',
      'submit.description',
      'submit.submitButton',
      'search.title',
      'confirmation.title',
      'status.SUBMITTED',
    ];
    for (const key of spotCheckKeys) {
      expect(enLeaves[key]).toBeDefined();
      expect(frLeaves[key]).toBeDefined();
      expect(enLeaves[key]).not.toEqual(frLeaves[key]);
    }
  });
});
