---
applyTo: '.copilot-tracking/changes/2026-02-19-ods-ui-compliance-changes.md'
---
<!-- markdownlint-disable-file -->
# Implementation Plan: Ontario Design System UI Compliance

## Overview

Replace the foundation-only ODS CSS package with the complete-styles package, fix component structural patterns, add Ontario branding assets, and remediate WCAG 2.2 Level AA accessibility gaps across all frontend components.

## Objectives

* Swap `@ongov/ontario-design-system-global-styles` for `@ongov/ontario-design-system-complete-styles@6.0.0` so all 35+ ODS component BEM classes render with proper CSS definitions
* Update Header with Ontario trillium logo, active navigation state, mobile toggle, and remove the dead `/review` link
* Fix alert sub-element structures (`__header` / `__body`) across SubmitProgram, SubmitConfirmation, and SearchPrograms
* Fix card sub-element structure in SubmitConfirmation
* Replace inline styles with ODS grid classes in SearchPrograms and wrap the table in `ontario-table-container`
* Add missing WCAG 2.2 Level AA attributes (`aria-required`, `lang`, `aria-current`, document lang sync)
* Replace Vite default favicon with Ontario government favicons
* Add missing i18n translation keys for alert headers

## Context Summary

### Project Files

* frontend/package.json — Contains `global-styles` dependency at L13; must swap to `complete-styles`
* frontend/src/main.tsx — CSS import at L3 references `global-styles` package path
* frontend/index.html — Vite favicon at L5; hardcoded title at L7; no `<meta name="description">`
* frontend/src/components/layout/Header.tsx — 49 lines; uses text logo, 3 nav links (one dead), no active state, no mobile toggle
* frontend/src/components/layout/Footer.tsx — 48 lines; 6 `ontario-footer__*` classes, no logo
* frontend/src/components/layout/Layout.tsx — 31 lines; missing `ontario-columns` wrapper at L23–L25
* frontend/src/components/common/LanguageToggle.tsx — 31 lines; missing `lang` attribute on button
* frontend/src/pages/SubmitProgram.tsx — 298 lines; flat alert at L117–L120, missing `aria-required` on inputs
* frontend/src/pages/SubmitConfirmation.tsx — 76 lines; flat alert at L39–L43, card missing `__content` at L46–L60
* frontend/src/pages/SearchPrograms.tsx — 161 lines; inline style at L82, flat alert at L109–L121, table at L129 without wrapper
* frontend/src/i18n.ts — 25 lines; no `languageChanged` listener, detection order missing `htmlTag`
* frontend/src/App.tsx — 26 lines; routes for `/`, `/confirmation`, `/search` only (no `/review`)
* frontend/public/locales/en/translation.json — 94 lines; missing `error.title` and `success.title` keys
* frontend/public/locales/fr/translation.json — 94 lines; missing `error.title` and `success.title` keys

### References

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md — Full research with code examples and ODS npm analysis
* Ontario Design System docs: designsystem.ontario.ca/docs/documentation/develop/npm-packages.html
* ODS Figma kit: assets/Ontario Design System UI prototyping kit.fig

### Standards References

* #file:../../.github/instructions/react.instructions.md — ODS class conventions, accessibility patterns, BEM naming
* #file:../../.github/copilot-instructions.md — WCAG 2.2 AA, i18next bilingual, Ontario Design System compliance

## Implementation Checklist

### [ ] Implementation Phase 1: CSS Package Swap and Favicons

<!-- parallelizable: false -->

* [ ] Step 1.1: Swap ODS npm package from global-styles to complete-styles
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 12-35)
* [ ] Step 1.2: Update CSS import path in main.tsx
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 37-64)
* [ ] Step 1.3: Replace Vite favicon with Ontario favicons and add meta description
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 66-111)
* [ ] Step 1.4: Validate phase changes
  * Run `npm install` to verify dependency resolution
  * Run `npm run build` to verify CSS import resolves
  * Visually confirm components render with ODS styles

### [ ] Implementation Phase 2: Header and Footer ODS Alignment

<!-- parallelizable: true -->

* [ ] Step 2.1: Rewrite Header with trillium logo, active nav state, mobile toggle, and remove dead /review link
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 115-170)
* [ ] Step 2.2: Add Ontario logo to Footer
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 172-200)
* [ ] Step 2.3: Validate phase changes
  * Run `npx tsc --noEmit` to verify TypeScript compilation
  * Run `npm run lint` to verify ESLint compliance

### [ ] Implementation Phase 3: Alert and Card Structure Fixes

<!-- parallelizable: true -->

* [ ] Step 3.1: Fix alert structure in SubmitProgram.tsx (L117–L120)
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 204-247)
* [ ] Step 3.2: Fix alert and card structure in SubmitConfirmation.tsx (L39–L43, L46–L60)
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 249-314)
* [ ] Step 3.3: Fix alert structure and replace inline styles in SearchPrograms.tsx (L82, L109–L121, L129)
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 316-400)

### [ ] Implementation Phase 4: Accessibility and i18n Remediation

<!-- parallelizable: true -->

* [ ] Step 4.1: Add `aria-required="true"` to required form inputs in SubmitProgram.tsx
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 404-446)
* [ ] Step 4.2: Add `lang` attribute to LanguageToggle button
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 448-495)
* [ ] Step 4.3: Add `ontario-columns` wrapper to Layout.tsx (L23–L25)
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 497-535)
* [ ] Step 4.4: Add language sync on init and languageChanged event in i18n.ts
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 537-588)
* [ ] Step 4.5: Add missing translation keys for alert headers in EN and FR locale files
  * Details: .copilot-tracking/details/2026-02-19-ods-ui-compliance-details.md (Lines 590-641)

### [ ] Implementation Phase 5: Validation

<!-- parallelizable: false -->

* [ ] Step 5.1: Run full project validation
  * Execute `npm run lint` for ESLint compliance
  * Execute `npx tsc --noEmit` for TypeScript type checking
  * Execute `npm run build` to verify production build succeeds
  * Run `npm test` for any existing test suites
* [ ] Step 5.2: Fix minor validation issues
  * Iterate on lint errors, TypeScript errors, and build warnings
  * Apply fixes directly when corrections are straightforward
* [ ] Step 5.3: Report blocking issues
  * Document issues requiring additional research
  * Provide user with next steps and recommended planning
  * Avoid large-scale fixes within this phase

## Dependencies

* Node.js and npm installed locally
* `@ongov/ontario-design-system-complete-styles@6.0.0` available on npm
* Ontario trillium logo SVG (available from `complete-styles` package `dist/assets/`)
* Ontario favicon files (available from `complete-styles` package `dist/favicons/`)
* React Router (`useLocation` hook for active nav state)

## Success Criteria

* All 41 ODS component BEM classes render with proper CSS definitions at runtime (up from 6/41)
* Header displays official Ontario trillium logo SVG and provides mobile navigation toggle
* All alert instances across 3 pages use `ontario-alert__header` / `ontario-alert__body` structure
* Card in SubmitConfirmation uses `ontario-card__content` wrapper
* Zero inline styles remain in component JSX
* `aria-required="true"` present on all 3 required form inputs
* `lang` attribute set on LanguageToggle button reflecting the target language
* `aria-current="page"` set on active navigation link
* `document.documentElement.lang` synced on i18n initialization and language change
* Ontario favicon replaces Vite default
* Dead `/review` nav link removed from Header
* `npm run build` completes without errors
* `npm run lint` passes without errors
