---
applyTo: "frontend/**/*.tsx,frontend/**/*.ts"
---
# React / TypeScript Instructions

## Ontario Design System
- Use Ontario Design System classes from @ongov/ontario-design-system-global-styles.
- Install with: npm install --save @ongov/ontario-design-system-global-styles
- Import theme: @import '@ongov/ontario-design-system-global-styles/dist/styles/css/compiled/ontario-theme.css'
- BEM naming convention: .ontario-{block}__{element}--{modifier}
- Wrap all pages in Ontario header and footer layout components.

## Internationalization
- Use i18next useTranslation() hook for all user-visible text.
- Never hardcode English or French strings directly in components.
- Store translations in public/locales/en/translation.json and public/locales/fr/translation.json.
- Set the lang attribute on the html element dynamically when language changes.
- Use lang attribute on individual elements when mixing languages (WCAG 3.1.2).

## WCAG 2.2 Accessibility
- Ensure focus indicators are visible on all interactive elements (2.4.7).
- Focus must not be obscured by sticky headers or modals (2.4.11).
- Provide non-drag alternatives for any drag interactions (2.5.7).
- Minimum touch target size: 24x24 CSS pixels (2.5.8).
- No cognitive function tests for authentication (3.3.8).
- Pre-fill previously entered data to avoid redundant entry (3.3.7).
- Place help mechanisms in consistent locations across pages (3.2.6).
- Identify form errors in text, not just color (3.3.1).
- Provide error suggestions for user input errors (3.3.3).
- Use ARIA live regions for dynamic status messages (4.1.3).

## Component Patterns
- Use functional components with hooks exclusively.
- Extract reusable UI into components/common/.
- Page components go in pages/.
- API calls go in services/api.ts.
- Custom hooks go in hooks/.
- TypeScript types go in types/.
