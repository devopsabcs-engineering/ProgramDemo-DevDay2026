# Ontario Design System (ODS) Codebase Audit

**Date:** 2025-07-24
**Auditor:** Research Subagent
**Scope:** All `.tsx` files in `frontend/src/` plus supporting configuration
**ODS Package:** `@ongov/ontario-design-system-global-styles` v6.0.0

---

## Executive Summary

**Total files audited:** 9 (`.tsx` files) + 5 supporting files (package.json, index.html, i18n.ts, vite.config.ts, translations)

### Critical Finding: Missing Component-Level CSS

The installed ODS package (`@ongov/ontario-design-system-global-styles` v6.0.0) is a **foundation-only** package. It provides:

- Grid system (`ontario-row`, `ontario-columns`, responsive size classes)
- Typography (`ontario-h1`–`ontario-h6`, `ontario-lead-statement`)
- Utility classes (margin, padding, background colors, visibility)
- Button base class (`ontario-button`)
- Form group base class (`ontario-form-group`)
- Ontario fonts (Open Sans, Raleway Modified, Courier Prime)

It does **NOT** provide CSS definitions for **any** of these component classes used in the codebase:

| Class Used in Code | CSS Definition Exists | Impact |
|---|---|---|
| `ontario-header` and sub-elements | **No** | Header renders unstyled |
| `ontario-footer` and sub-elements | **No** | Footer renders unstyled |
| `ontario-alert` and modifiers | **No** | Alerts render unstyled |
| `ontario-table` | **No** | Table renders unstyled |
| `ontario-card` | **No** | Card renders unstyled |
| `ontario-input` | **No** | Inputs render unstyled |
| `ontario-label` and sub-elements | **No** | Labels render unstyled |
| `ontario-textarea` | **No** | Textarea renders unstyled |
| `ontario-dropdown` | **No** | Select renders unstyled |
| `ontario-skip-navigation` | **No** | Skip link renders unstyled |
| `ontario-error-messaging` | **No** | Error messages render unstyled |
| `ontario-description-list` | **No** | Description list renders unstyled |
| `ontario-loading-indicator` | **No** | Loading state renders unstyled |
| `ontario-button-group` | **No** | Button group renders unstyled |

**No custom CSS files exist** in the project to compensate. The project has zero `.css`, `.scss`, or `.less` files in `frontend/src/`.

---

## File-by-File Audit

### 1. `frontend/index.html`

**Lines:** 1–14

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | Favicon uses Vite default (`/vite.svg`) instead of Ontario government favicon | High | L5 |
| 2 | No Ontario favicon meta tags (apple-touch-icon, etc.) — ODS provides these in `dist/favicons/` | High | L4–L6 |
| 3 | Page title is generic — should use i18n-compatible meta title | Low | L7 |
| 4 | Missing `<meta name="description">` tag | Medium | — |
| 5 | Missing ODS font preconnect/preload hints | Low | — |

**Fix needed:**

```html
<link rel="icon" type="image/svg+xml" href="/favicon.svg" />
<link rel="icon" type="image/x-icon" href="/favicon.ico" />
<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
<meta name="description" content="Ontario Program Services Portal" />
```

Copy ODS favicons from `node_modules/@ongov/ontario-design-system-global-styles/dist/favicons/` to `frontend/public/`.

---

### 2. `frontend/src/main.tsx` (Lines 1–13)

#### ODS Classes Used

- `ontario-loading-indicator` (L9) — **no CSS definition exists**

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | CSS import path uses `/styles/css/compiled/` — react.instructions.md specifies `/dist/styles/css/compiled/` | Medium | L3 |
| 2 | `ontario-loading-indicator` class has no CSS definition in the package | High | L9 |
| 3 | Hardcoded string `"Loading…"` not i18n-ized (rendered before i18n initializes — acceptable as Suspense fallback but should note) | Low | L9 |

**Current import (L3):**

```tsx
import '@ongov/ontario-design-system-global-styles/styles/css/compiled/ontario-theme.min.css';
```

**Recommended import:**

```tsx
import '@ongov/ontario-design-system-global-styles/dist/styles/css/compiled/ontario-theme.min.css';
```

> Note: The current import works because Vite resolves from the package root. Both paths resolve to the same file.

---

### 3. `frontend/src/App.tsx` (Lines 1–28)

#### ODS Classes Used

None directly — this is a routing shell.

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | No ODS-related issues — correctly delegates to Layout | None | — |

**Status:** Clean

---

### 4. `frontend/src/components/layout/Layout.tsx` (Lines 1–30)

#### ODS Classes Used

- `ontario-skip-navigation` (L20) — **no CSS definition**
- `ontario-main` (L23) — **no CSS definition**
- `ontario-row` (L24)

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | `ontario-skip-navigation` has no CSS — skip link will not be visually hidden or styled | High | L20 |
| 2 | `ontario-main` is not a defined ODS class | Medium | L23 |
| 3 | Main content area lacks column constraints — should use `ontario-columns ontario-small-12` for content width | Medium | L24–L26 |
| 4 | Skip link `href="#main-content"` is correct — targets `id="main-content"` on `<main>` | OK | L20, L23 |
| 5 | `tabIndex={-1}` on main is correct for focus management | OK | L23 |

**Recommended structure for main content:**

```tsx
<main id="main-content" className="ontario-main" tabIndex={-1}>
  <div className="ontario-row">
    <div className="ontario-columns ontario-small-12">
      <Outlet />
    </div>
  </div>
</main>
```

---

### 5. `frontend/src/components/layout/Header.tsx` (Lines 1–50)

#### ODS Classes Used

- `ontario-header` (L15) — **no CSS definition**
- `ontario-row` (L16, L27, L44)
- `ontario-header__container` (L17) — **no CSS definition**
- `ontario-header__logo-container` (L18) — **no CSS definition**
- `ontario-header__logo` (L19) — **no CSS definition**
- `ontario-header__nav` (L28) — **no CSS definition**
- `ontario-header__nav-list` (L29) — **no CSS definition**
- `ontario-header__nav-item` (L30, 35, 40) — **no CSS definition**
- `ontario-header__nav-link` (L31, 36, 41) — **no CSS definition**
- `ontario-header__heading` (L46) — **no CSS definition**

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | **No Ontario trillium logo SVG** — uses text `"Ontario.ca"` instead of the official Ontario trillium SVG logo | High | L19 |
| 2 | **No mobile hamburger menu** — no responsive menu toggle for small screens | High | — |
| 3 | **No active nav link state** — all nav links use the same class; no `ontario-header__nav-link--active` or `aria-current="page"` attribute | High | L31, L36, L41 |
| 4 | All 10 `ontario-header__*` classes have **no CSS definitions** in the installed package | Critical | L15–L47 |
| 5 | Navigation link to `/review` exists but no corresponding route in App.tsx | Medium | L40–L43 |
| 6 | Missing `role="navigation"` is OK since `<nav>` is used | OK | L28 |
| 7 | `role="banner"` on header is redundant (implicit for `<header>`) but harmless | Low | L15 |
| 8 | No `ontario-header__search` component for site search | Low | — |

**Recommended fixes:**

1. Add Ontario trillium logo SVG inline or as an imported asset
2. Add hamburger menu toggle button for mobile:

```tsx
<button className="ontario-header__menu-toggler" aria-label={t('header.menu')} aria-expanded={menuOpen}>
  <span className="ontario-icon ontario-icon--menu" />
</button>
```

3. Use `useLocation()` to set active state:

```tsx
import { Link, useLocation } from 'react-router-dom';
// ...
const location = useLocation();
// ...
<Link
  to="/"
  className={`ontario-header__nav-link ${location.pathname === '/' ? 'ontario-header__nav-link--active' : ''}`}
  aria-current={location.pathname === '/' ? 'page' : undefined}
>
```

---

### 6. `frontend/src/components/layout/Footer.tsx` (Lines 1–47)

#### ODS Classes Used

- `ontario-footer` (L13) — **no CSS definition**
- `ontario-row` (L14)
- `ontario-footer__container` (L15) — **no CSS definition**
- `ontario-footer__list` (L16) — **no CSS definition**
- `ontario-footer__list-item` (L17, 24, 31) — **no CSS definition**
- `ontario-footer__link` (L20, 27, 34) — **no CSS definition**
- `ontario-footer__copyright` (L39) — **no CSS definition**

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | **No Ontario logo** in footer — ODS footer pattern requires the Ontario logo | High | — |
| 2 | **No multi-column link layout** — ODS footer uses `ontario-footer__links-container` with column groups | Medium | L16 |
| 3 | All 6 `ontario-footer__*` classes have **no CSS definitions** | Critical | L13–L41 |
| 4 | `role="contentinfo"` is redundant (implicit for `<footer>`) but harmless | Low | L13 |
| 5 | Missing `ontario-footer__top-level-link` pattern for primary footer links | Medium | — |
| 6 | Missing `ontario-footer__expanded-bottom-container` for bottom section with logo | Medium | — |
| 7 | External links missing `target="_blank"` and `rel="noopener noreferrer"` | Low | L18–L35 |
| 8 | External links missing external link indicator for accessibility | Low | L18–L35 |

**Recommended structure:**

```tsx
<footer className="ontario-footer" role="contentinfo">
  <div className="ontario-footer__expanded-top-container">
    <div className="ontario-row">
      {/* Multi-column link groups */}
    </div>
  </div>
  <div className="ontario-footer__expanded-bottom-container">
    <div className="ontario-row">
      <div className="ontario-footer__logo-container">
        {/* Ontario logo SVG */}
      </div>
      <ul className="ontario-footer__list">
        {/* Footer bottom links */}
      </ul>
    </div>
  </div>
</footer>
```

---

### 7. `frontend/src/components/common/LanguageToggle.tsx` (Lines 1–30)

#### ODS Classes Used

- `ontario-header__language-toggler` (L22) — **no CSS definition**

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | `ontario-header__language-toggler` has **no CSS definition** | High | L22 |
| 2 | Toggle correctly updates `document.documentElement.lang` (WCAG 3.1.1) | OK | L16 |
| 3 | Has proper `aria-label` | OK | L25 |
| 4 | No abbreviation indicator (e.g., `lang="fr"` attribute on the French text or `lang="en"` on English text when showing the other language) | Medium | L27 |

**Recommended fix for language attribute:**

```tsx
<button
  type="button"
  className="ontario-header__language-toggler"
  onClick={handleToggle}
  aria-label={t('language.label')}
  lang={i18n.language === 'en' ? 'fr' : 'en'}
>
  {t('language.toggle')}
</button>
```

This satisfies WCAG 3.1.2 (Language of Parts) since the button text is in the *other* language.

---

### 8. `frontend/src/pages/SubmitProgram.tsx` (Lines 1–228)

#### ODS Classes Used

- `ontario-h2` (L104)
- `ontario-lead-statement` (L107)
- `ontario-alert ontario-alert--error` (L110) — **no CSS definition**
- `ontario-form-group` (L115, L134, L157, L186, L207)
- `ontario-label` (L116, L135, L158, L187, L208)
- `ontario-label__flag` (L118, L137, L160) — **no CSS definition**
- `ontario-error-messaging` (L122, L141, L164, L194) — **no CSS definition**
- `ontario-input` (L130, L149, L176, L202, L214)
- `ontario-input--error` (L131, L150, L177, L203) — **no CSS definition**
- `ontario-textarea` (L149) — **no CSS definition**
- `ontario-dropdown` (L176) — **no CSS definition**
- `ontario-button ontario-button--primary` (L222)

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | Alert missing `ontario-alert__header` and `ontario-alert__body` sub-elements | High | L110–L112 |
| 2 | `ontario-label__flag` has **no CSS definition** | Medium | L118, L137, L160 |
| 3 | `ontario-error-messaging` has **no CSS definition** | High | L122, L141, L164, L194 |
| 4 | `ontario-input--error` has **no CSS definition** — error state not visually indicated | High | L131, L150, L177, L203 |
| 5 | `ontario-textarea` has **no CSS definition** | Medium | L149 |
| 6 | `ontario-dropdown` has **no CSS definition** | Medium | L176 |
| 7 | No `ontario-hint-expander` or `ontario-hint-text` for form field help text | Low | — |
| 8 | `placeholder` attributes used — ODS recommends hint text above the input instead | Low | L132, L153, L206, L216 |
| 9 | No error summary at top of form listing all errors (WCAG 3.3.1 best practice) | Medium | — |
| 10 | No focus management on error — should focus the first error field or error summary | Medium | — |
| 11 | Form does not use `ontario-columns` grid for field width control | Low | — |
| 12 | Missing `aria-required="true"` on required fields | Medium | L130, L149, L176 |

**Alert fix needed (L110–L112):**

```tsx
{serverError && (
  <div className="ontario-alert ontario-alert--error" role="alert">
    <div className="ontario-alert__header">
      <h3 className="ontario-alert__header-title">{t('error.title')}</h3>
    </div>
    <div className="ontario-alert__body">
      <p>{serverError}</p>
    </div>
  </div>
)}
```

**Error summary pattern needed before the form:**

```tsx
{Object.keys(errors).length > 0 && (
  <div className="ontario-alert ontario-alert--error" role="alert" aria-labelledby="error-summary-heading">
    <div className="ontario-alert__header">
      <h3 id="error-summary-heading">{t('validation.errorSummary')}</h3>
    </div>
    <div className="ontario-alert__body">
      <ul>
        {Object.entries(errors).map(([field, msg]) => (
          <li key={field}><a href={`#${field}`}>{msg}</a></li>
        ))}
      </ul>
    </div>
  </div>
)}
```

---

### 9. `frontend/src/pages/SubmitConfirmation.tsx` (Lines 1–73)

#### ODS Classes Used

- `ontario-h2` (L20, L42)
- `ontario-button ontario-button--secondary` (L23)
- `ontario-alert ontario-alert--success` (L40) — **no CSS definition**
- `ontario-card` (L47) — **no CSS definition**
- `ontario-description-list` (L48) — **no CSS definition**
- `ontario-h4` (L60)
- `ontario-button-group` (L63) — **no CSS definition**
- `ontario-button ontario-button--tertiary` (L67)

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | Alert missing `ontario-alert__header` and `ontario-alert__body` sub-elements | High | L40–L44 |
| 2 | `ontario-alert--success` has **no CSS definition** | High | L40 |
| 3 | `ontario-card` missing `ontario-card__content` sub-element | Medium | L47 |
| 4 | `ontario-description-list` has **no CSS definition** | Medium | L48 |
| 5 | `ontario-button-group` has **no CSS definition** | Medium | L63 |
| 6 | `<h2>` inside alert should be `<h3>` or use `ontario-alert__header-title` | Low | L42 |
| 7 | `<h3>` uses `ontario-h4` class — heading level mismatch confusing | Low | L60 |
| 8 | No `role="alert"` or `aria-live` on the success alert `role="status"` is used — this is correct | OK | L40 |

**Alert fix needed (L40–L44):**

```tsx
<div className="ontario-alert ontario-alert--success" role="status">
  <div className="ontario-alert__header">
    <h2 id="confirmation-heading" className="ontario-alert__header-title">
      {t('confirmation.title')}
    </h2>
  </div>
  <div className="ontario-alert__body">
    <p>{t('confirmation.message')}</p>
  </div>
</div>
```

**Card fix needed (L47–L56):**

```tsx
<div className="ontario-card">
  <div className="ontario-card__content">
    <dl className="ontario-description-list">
      {/* ... */}
    </dl>
  </div>
</div>
```

---

### 10. `frontend/src/pages/SearchPrograms.tsx` (Lines 1–152)

#### ODS Classes Used

- `ontario-h2` (L70)
- `ontario-lead-statement` (L73)
- `ontario-form-group` (L78)
- `ontario-label ontario-label--visually-hidden` (L82) — **no CSS definition for `--visually-hidden`**
- `ontario-input` (L86)
- `ontario-button ontario-button--primary` (L93)
- `ontario-button ontario-button--tertiary` (L100)
- `ontario-alert ontario-alert--error` (L113) — **no CSS definition**
- `ontario-button ontario-button--secondary` (L116)
- `ontario-table` (L127) — **no CSS definition**

#### Issues Found

| # | Issue | Severity | Line(s) |
|---|---|---|---|
| 1 | **Inline style** `style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-end' }}` — should use ODS grid classes | High | L84 |
| 2 | `ontario-label--visually-hidden` has **no CSS definition** — sr-only label won't work | High | L82 |
| 3 | Table not wrapped in `ontario-table-container` | Medium | L127 |
| 4 | Alert missing `ontario-alert__header` and `ontario-alert__body` sub-elements | High | L113–L120 |
| 5 | `ontario-table` has **no CSS definition** | High | L127 |
| 6 | Table action buttons use `ontario-button--tertiary` which may render oversized in table cells | Low | L143 |
| 7 | No empty state visual beyond text paragraph | Low | L111 |
| 8 | No pagination for large result sets | Medium | — |
| 9 | No ARIA live region wrapping the search results count for screen readers | Medium | — |
| 10 | Link to `/programs/${program.id}` has no corresponding route in App.tsx | Medium | L140 |

**Inline style fix (L84):**

Replace:

```tsx
<div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-end' }}>
```

With:

```tsx
<div className="ontario-row">
  <div className="ontario-columns ontario-small-8 ontario-medium-6">
    {/* search input */}
  </div>
  <div className="ontario-columns ontario-small-4 ontario-medium-6">
    {/* buttons */}
  </div>
</div>
```

**Table wrapper fix (L127):**

```tsx
<div className="ontario-table-container">
  <table className="ontario-table" aria-label={t('search.title')}>
    {/* ... */}
  </table>
</div>
```

---

### 11. `frontend/src/i18n.ts` (Lines 1–25)

#### Issues Found

| # | Issue | Severity |
|---|---|---|
| 1 | No initialization of `document.documentElement.lang` to match detected language on app load | Medium |
| 2 | `detection.order` doesn't include `htmlTag` which would auto-set the lang attribute | Medium |

**Recommended fix:**

```typescript
i18n.on('languageChanged', (lng) => {
  document.documentElement.lang = lng;
});
```

---

## ODS Classes Summary

### Classes Currently Used Across the Project (28 unique)

| Class | Files Used In | CSS Exists |
|---|---|---|
| `ontario-row` | Layout, Header, Footer | Yes |
| `ontario-h2` | SubmitProgram, SubmitConfirmation, SearchPrograms | Yes |
| `ontario-h4` | SubmitConfirmation | Yes |
| `ontario-lead-statement` | SubmitProgram, SearchPrograms | Yes |
| `ontario-button` | SubmitProgram, SubmitConfirmation, SearchPrograms | Yes |
| `ontario-button--primary` | SubmitProgram, SearchPrograms | Partial |
| `ontario-button--secondary` | SubmitConfirmation, SearchPrograms | Partial |
| `ontario-button--tertiary` | SubmitConfirmation, SearchPrograms | Partial |
| `ontario-form-group` | SubmitProgram, SearchPrograms | Yes |
| `ontario-header` | Header | **No** |
| `ontario-header__container` | Header | **No** |
| `ontario-header__logo-container` | Header | **No** |
| `ontario-header__logo` | Header | **No** |
| `ontario-header__nav` | Header | **No** |
| `ontario-header__nav-list` | Header | **No** |
| `ontario-header__nav-item` | Header | **No** |
| `ontario-header__nav-link` | Header | **No** |
| `ontario-header__heading` | Header | **No** |
| `ontario-header__language-toggler` | LanguageToggle | **No** |
| `ontario-footer` | Footer | **No** |
| `ontario-footer__container` | Footer | **No** |
| `ontario-footer__list` | Footer | **No** |
| `ontario-footer__list-item` | Footer | **No** |
| `ontario-footer__link` | Footer | **No** |
| `ontario-footer__copyright` | Footer | **No** |
| `ontario-skip-navigation` | Layout | **No** |
| `ontario-alert` / `--error` / `--success` | SubmitProgram, SubmitConfirmation, SearchPrograms | **No** |
| `ontario-label` | SubmitProgram, SearchPrograms | **No** |
| `ontario-label__flag` | SubmitProgram | **No** |
| `ontario-label--visually-hidden` | SearchPrograms | **No** |
| `ontario-input` | SubmitProgram, SearchPrograms | **No** |
| `ontario-input--error` | SubmitProgram | **No** |
| `ontario-textarea` | SubmitProgram | **No** |
| `ontario-dropdown` | SubmitProgram | **No** |
| `ontario-error-messaging` | SubmitProgram | **No** |
| `ontario-table` | SearchPrograms | **No** |
| `ontario-card` | SubmitConfirmation | **No** |
| `ontario-description-list` | SubmitConfirmation | **No** |
| `ontario-button-group` | SubmitConfirmation | **No** |
| `ontario-loading-indicator` | main.tsx | **No** |
| `ontario-main` | Layout | **No** |

**Result:** 6 classes have CSS definitions. 35+ classes have **NO CSS definitions**.

### Missing ODS Patterns Not Yet Used

| Pattern | Where Needed |
|---|---|
| `ontario-alert__header` / `ontario-alert__body` | All alert instances |
| `ontario-card__content` | SubmitConfirmation |
| `ontario-table-container` | SearchPrograms |
| `ontario-header__nav-link--active` / `aria-current="page"` | Header |
| Ontario trillium logo SVG | Header, Footer |
| Mobile hamburger menu (`ontario-header__menu-toggler`) | Header |
| `ontario-hint-text` | Form fields |
| Error summary pattern at form top | SubmitProgram |
| `ontario-footer__expanded-top-container` / `__expanded-bottom-container` | Footer |
| `ontario-footer__logo-container` | Footer |
| `ontario-breadcrumbs` | Page navigation |
| `ontario-back-to-top` | Long pages |
| `ontario-callout` | Information highlights |
| `ontario-columns` for field width control | Form layouts |

---

## Priority Ranking of Fixes

### Priority 1 — Critical (Blocking: No visual styling at all)

| # | Issue | Files Affected | Effort |
|---|---|---|---|
| **C1** | **Install ODS component library** or create custom CSS for all 35+ unstyled component classes. The `@ongov/ontario-design-system-global-styles` package only provides grid/typography/utilities. Component styles (header, footer, alert, table, card, input, label, etc.) require either the ODS Web Components library (`@ongov/ontario-design-system-component-library`) or a custom CSS implementation. | ALL | High |
| **C2** | **Add Ontario favicons** — copy from `node_modules/@ongov/.../dist/favicons/` to `public/` and update `index.html` | index.html | Low |

### Priority 2 — High (ODS Pattern Violations)

| # | Issue | Files Affected | Effort |
|---|---|---|---|
| **H1** | Add Ontario trillium logo SVG to Header | Header.tsx | Low |
| **H2** | Add mobile hamburger menu toggle | Header.tsx | Medium |
| **H3** | Add active nav link state with `aria-current="page"` | Header.tsx | Low |
| **H4** | Add `ontario-alert__header` and `ontario-alert__body` sub-elements to all alerts | SubmitProgram, SubmitConfirmation, SearchPrograms | Low |
| **H5** | Remove inline styles — use ODS grid classes instead | SearchPrograms.tsx L84 | Low |
| **H6** | Add Ontario logo to footer | Footer.tsx | Low |
| **H7** | Add error summary at top of form with links to error fields | SubmitProgram.tsx | Medium |
| **H8** | Add `ontario-table-container` wrapper around data table | SearchPrograms.tsx | Low |
| **H9** | Add `aria-required="true"` to required form fields | SubmitProgram.tsx | Low |
| **H10** | Add `lang` attribute to LanguageToggle button text | LanguageToggle.tsx | Low |

### Priority 3 — Medium (Accessibility & UX improvements)

| # | Issue | Files Affected | Effort |
|---|---|---|---|
| **M1** | Add `ontario-card__content` sub-element to card | SubmitConfirmation.tsx | Low |
| **M2** | Add `document.documentElement.lang` sync on i18n init | i18n.ts | Low |
| **M3** | Add focus management on form validation errors | SubmitProgram.tsx | Medium |
| **M4** | Add pagination for search results | SearchPrograms.tsx | Medium |
| **M5** | Add ARIA live region for search result count | SearchPrograms.tsx | Low |
| **M6** | Add multi-column footer layout | Footer.tsx | Medium |
| **M7** | Fix dead routes: `/review` nav link, `/programs/:id` view link | App.tsx, Header.tsx | Medium |
| **M8** | Add `<meta name="description">` to index.html | index.html | Low |
| **M9** | Add `ontario-columns` grid to main content wrapper | Layout.tsx | Low |
| **M10** | Remove placeholder attributes — use hint text per ODS pattern | SubmitProgram.tsx | Low |

### Priority 4 — Low (Polish)

| # | Issue | Files Affected | Effort |
|---|---|---|---|
| **L1** | Add `target="_blank"` and `rel="noopener noreferrer"` to external footer links | Footer.tsx | Low |
| **L2** | Remove redundant ARIA roles (`role="banner"`, `role="contentinfo"`) | Header.tsx, Footer.tsx | Low |
| **L3** | Fix heading hierarchy: `<h3 className="ontario-h4">` is confusing | SubmitConfirmation.tsx | Low |
| **L4** | Add ODS font preload hints | index.html | Low |
| **L5** | Add `ontario-breadcrumbs` component | New component | Medium |
| **L6** | Add `ontario-back-to-top` component | New component | Medium |

---

## I18n Compliance Summary

| Status | Details |
|---|---|
| **EN translation keys** | 92 keys — complete |
| **FR translation keys** | 92 keys — complete, matches EN |
| **Hardcoded strings** | 1 instance: `"Loading…"` in main.tsx Suspense fallback (acceptable — i18n not yet loaded) |
| **lang attribute** | Set on toggle; missing on app init |
| **WCAG 3.1.2 (Language of Parts)** | Missing `lang` attribute on LanguageToggle button text |

---

## Accessibility (WCAG 2.2) Compliance Summary

| WCAG Criterion | Status | Details |
|---|---|---|
| 2.4.1 Skip Navigation | Partial | Link exists but has no CSS styling |
| 2.4.7 Focus Visible | Unknown | No custom focus styles; depends on browser defaults + ODS (which is missing) |
| 2.4.11 Focus Not Obscured | OK | No sticky elements (header is static) |
| 3.1.1 Language of Page | Partial | Set on toggle but not on init |
| 3.1.2 Language of Parts | Missing | LanguageToggle button text needs `lang` attribute |
| 3.3.1 Error Identification | Partial | Individual field errors shown; no error summary |
| 3.3.3 Error Suggestion | OK | Descriptive error messages provided |
| 4.1.3 Status Messages | OK | `role="alert"` and `aria-live="polite"` used appropriately |

---

## Recommendations

1. **Immediate action:** Investigate the Ontario Design System component library for React. The `@ongov/ontario-design-system-global-styles` package is only the foundation layer. Component-level styling requires either:
   - The ODS Web Components library: `@ongov/ontario-design-system-component-library`
   - Custom CSS implementing all ODS BEM component patterns
   - A copy of the component CSS from the full ODS distribution

2. **Create a custom CSS file** (`frontend/src/styles/ontario-components.css`) if the component library cannot be used, implementing at minimum: header, footer, alert, table, input, label, card, skip-navigation, error-messaging, and button modifier styles.

3. **Copy ODS favicons** from the package to `frontend/public/` and update `index.html`.

4. **Add the Ontario trillium logo** as an SVG asset and use it in both Header and Footer.

5. **Fix all alert patterns** to include proper `__header` and `__body` sub-elements.

6. **Remove all inline styles** and replace with ODS grid classes.
