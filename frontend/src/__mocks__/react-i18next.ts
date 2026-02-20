/**
 * Manual mock for react-i18next.
 *
 * Returns the translation key as the translated value, which makes
 * test assertions predictable without loading locale files.
 *
 * Usage in test files:
 *   vi.mock('react-i18next', () => import('../__mocks__/react-i18next'))
 */
import { vi } from 'vitest';

const usedNamespaces: string[] = [];

export const useTranslation = vi.fn(() => ({
  t: (key: string) => key,
  i18n: {
    language: 'en',
    changeLanguage: vi.fn(),
  },
}));

export const initReactI18next = {
  type: '3rdParty' as const,
  init: vi.fn(),
};

export const Trans = ({ i18nKey }: { i18nKey: string }) => i18nKey;

export default { useTranslation, initReactI18next, Trans, usedNamespaces };
