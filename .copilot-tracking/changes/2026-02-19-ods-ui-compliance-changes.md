<!-- markdownlint-disable-file -->
# Release Changes: Ontario Design System UI Compliance

**Related Plan**: 2026-02-19-ods-ui-compliance-plan.instructions.md
**Implementation Date**: 2026-02-19

## Summary

Replace foundation-only ODS CSS with complete-styles package, fix component BEM structures, add Ontario branding assets, and remediate WCAG 2.2 Level AA accessibility gaps across all frontend components.

## Changes

### Added

* frontend/public/ontario-logo.svg — Ontario trillium SVG logo for header and footer branding

### Modified

* frontend/package.json — Swapped `@ongov/ontario-design-system-global-styles` for `@ongov/ontario-design-system-complete-styles@6.0.0`
* frontend/src/main.tsx — Updated CSS import path to reference `complete-styles` package
* frontend/index.html — Replaced Vite favicon link with `/favicon.ico`, added bilingual `<meta name="description">`
* frontend/package-lock.json — Auto-updated by npm
* frontend/src/components/layout/Header.tsx — Rewrote with trillium logo, active nav state, mobile toggle, removed `/review` link
* frontend/src/components/layout/Footer.tsx — Added Ontario logo with link to ontario.ca
* frontend/public/locales/en/translation.json — Added `header.menuToggle`, removed `header.nav.review`, added `error.title` and `success.title` keys
* frontend/public/locales/fr/translation.json — Added `header.menuToggle`, removed `header.nav.review`, added `error.title` and `success.title` keys
* frontend/src/pages/SubmitProgram.tsx — Fixed alert to use `__header`/`__body` sub-elements; added `aria-required="true"` to 3 required inputs
* frontend/src/pages/SubmitConfirmation.tsx — Fixed alert to use `__header`/`__body` sub-elements; wrapped card content in `ontario-card__content`
* frontend/src/pages/SearchPrograms.tsx — Fixed alert structure; replaced inline styles with ODS grid; wrapped table in `ontario-table-container`
* frontend/src/components/common/LanguageToggle.tsx — Added `lang` attribute reflecting target language
* frontend/src/components/layout/Layout.tsx — Added `ontario-columns ontario-small-12` wrapper around Outlet
* frontend/src/i18n.ts — Added `htmlTag` to detection order; added `languageChanged` listener and init sync for `document.documentElement.lang`

### Removed

* frontend/public/vite.svg — Removed Vite default favicon

## Additional or Deviating Changes

* ODS complete-styles package `dist/favicons/` directory does not exist — favicon.ico reference in index.html will need a real favicon file added separately from Ontario brand assets
* ODS complete-styles package `dist/assets/` directory is empty — Ontario logo SVG was created manually instead of copied from the package
* SubmitConfirmation.tsx — Moved heading outside alert to avoid duplicate `id` attributes; alert header uses `h3` instead of `h2` to maintain heading hierarchy

## Release Summary

Total files affected: 14 (1 created, 12 modified, 1 removed)

**Created:**
* frontend/public/ontario-logo.svg — Ontario trillium SVG logo for header/footer branding

**Modified:**
* frontend/package.json — Swapped ODS CSS package dependency
* frontend/package-lock.json — Auto-updated by npm
* frontend/index.html — Favicon and meta description updates
* frontend/src/main.tsx — CSS import path update
* frontend/src/components/layout/Header.tsx — Full rewrite with logo, active nav, mobile toggle
* frontend/src/components/layout/Footer.tsx — Added Ontario logo
* frontend/src/components/layout/Layout.tsx — Added ontario-columns wrapper
* frontend/src/components/common/LanguageToggle.tsx — Added lang attribute
* frontend/src/pages/SubmitProgram.tsx — Alert structure fix, aria-required on 3 inputs
* frontend/src/pages/SubmitConfirmation.tsx — Alert structure fix, card content wrapper
* frontend/src/pages/SearchPrograms.tsx — Alert structure, ODS grid, table container
* frontend/src/i18n.ts — Language detection order, document lang sync
* frontend/public/locales/en/translation.json — New keys, removed review nav
* frontend/public/locales/fr/translation.json — New keys, removed review nav

**Removed:**
* frontend/public/vite.svg — Vite default favicon

**Dependency changes:** `@ongov/ontario-design-system-global-styles` replaced by `@ongov/ontario-design-system-complete-styles@6.0.0`

**Notes:**
* No ODS favicon files found in the `complete-styles` package — favicon.ico will need to be sourced from Ontario brand assets separately
* Ontario logo SVG was created manually as the package's `dist/assets/` directory was empty
