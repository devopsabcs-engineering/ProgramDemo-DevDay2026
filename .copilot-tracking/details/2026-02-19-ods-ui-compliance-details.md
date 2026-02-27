<!-- markdownlint-disable-file -->
# Implementation Details: Ontario Design System UI Compliance

## Context Reference

Sources: .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md, subagent file audit (2026-02-19), Ontario Design System npm docs

## Implementation Phase 1: CSS Package Swap and Favicons

<!-- parallelizable: false -->

### Step 1.1: Swap ODS npm package from global-styles to complete-styles

Replace the foundation-only CSS package with the complete package that includes all 35+ component class definitions.

Run in `frontend/` directory:

```bash
npm uninstall @ongov/ontario-design-system-global-styles
npm install @ongov/ontario-design-system-complete-styles@6.0.0
```

Files:

* frontend/package.json — L13: change dependency from `@ongov/ontario-design-system-global-styles` to `@ongov/ontario-design-system-complete-styles`

Success criteria:

* `package.json` lists `@ongov/ontario-design-system-complete-styles` as a dependency
* `node_modules/@ongov/ontario-design-system-complete-styles/` directory exists
* `node_modules/@ongov/ontario-design-system-global-styles/` directory no longer exists

Dependencies:

* npm and Node.js available

### Step 1.2: Update CSS import path in main.tsx

Change the CSS import to reference the new package name. The file path within the package is identical (`styles/css/compiled/ontario-theme.min.css`).

Files:

* frontend/src/main.tsx — L3: change import path

Before:

```tsx
import '@ongov/ontario-design-system-global-styles/styles/css/compiled/ontario-theme.min.css';
```

After:

```tsx
import '@ongov/ontario-design-system-complete-styles/styles/css/compiled/ontario-theme.min.css';
```

Success criteria:

* `npm run build` resolves the CSS import without errors
* The compiled CSS bundle includes component-level styles (header, footer, alert, etc.)

Dependencies:

* Step 1.1 completion

### Step 1.3: Replace Vite favicon with Ontario favicons and add meta description

Copy Ontario government favicon files from the `complete-styles` package into `frontend/public/` and update `index.html` to reference them.

Check if favicons exist at: `node_modules/@ongov/ontario-design-system-complete-styles/dist/favicons/`

If the favicons directory exists, copy files:

```bash
cp node_modules/@ongov/ontario-design-system-complete-styles/dist/favicons/* public/
```

If not available in the package, obtain Ontario favicon from the Ontario Design System CDN or create a minimal favicon using the Ontario trillium mark.

Files:

* frontend/index.html — L5–L7: replace favicon link, add apple-touch-icon and meta description
* frontend/public/ — Add favicon.ico, apple-touch-icon.png (if available from package)

Before (index.html L5):

```html
<link rel="icon" type="image/svg+xml" href="/vite.svg" />
```

After (index.html L5–L7, insert before existing L6):

```html
<link rel="icon" type="image/x-icon" href="/favicon.ico" />
<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
<meta name="description" content="Ontario Program Services Portal / Portail des services de programmes de l'Ontario" />
```

Also remove the now-unused `frontend/public/vite.svg` file.

Success criteria:

* Browser tab shows Ontario favicon instead of Vite logo
* `<meta name="description">` present in HTML head
* `vite.svg` no longer in `public/` directory

Dependencies:

* Step 1.1 completion (package installed to access favicon assets)

## Implementation Phase 2: Header and Footer ODS Alignment

<!-- parallelizable: true -->

### Step 2.1: Rewrite Header with trillium logo, active nav state, mobile toggle, and remove dead /review link

Rewrite `Header.tsx` to include: Ontario trillium logo SVG, `useLocation()` for active state with `aria-current="page"`, mobile hamburger toggle button, and only 2 nav links (Submit and Search — removing the dead `/review` link).

Files:

* frontend/src/components/layout/Header.tsx — Full rewrite (49 lines → approximately 70 lines)

Key changes:

1. **Logo**: Replace `<span>Ontario.ca</span>` (L19) with inline SVG of Ontario trillium logotype or `<img>` referencing the SVG from `complete-styles` assets. The SVG is available at `node_modules/@ongov/ontario-design-system-complete-styles/dist/assets/`. Copy the SVG to `frontend/public/ontario-logo.svg` and use `<img src="/ontario-logo.svg" alt="" />` inside the logo link, or inline the SVG directly.

2. **Active nav state**: Import `useLocation` from `react-router-dom`. Compare `location.pathname` to each nav item's `to` property. Add `ontario-header__nav-link--active` class and `aria-current="page"` when active.

3. **Mobile toggle**: Add a `<button>` with class `ontario-header__menu-toggler` before the nav list. Use local state (`useState`) to toggle visibility of `ontario-header__nav-list` on mobile. Add `aria-expanded` and `aria-controls` attributes.

4. **Remove /review**: Delete the nav list item for `/review` (L37–L40). Only keep Submit (`/`) and Search (`/search`).

Pattern for nav items:

```tsx
const navItems = [
  { to: '/', labelKey: 'header.nav.submit' },
  { to: '/search', labelKey: 'header.nav.search' },
];
```

```tsx
{navItems.map(({ to, labelKey }) => (
  <li key={to} className="ontario-header__nav-item">
    <Link
      to={to}
      className={`ontario-header__nav-link${location.pathname === to ? ' ontario-header__nav-link--active' : ''}`}
      aria-current={location.pathname === to ? 'page' : undefined}
    >
      {t(labelKey)}
    </Link>
  </li>
))}
```

Success criteria:

* Ontario trillium logo visible in header
* Active nav link has `ontario-header__nav-link--active` class and `aria-current="page"`
* Mobile menu toggle button present with `aria-expanded` attribute
* No `/review` nav link in rendered output
* TypeScript compiles without errors

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 163-207) — Header fix example

Dependencies:

* Phase 1 completion (complete-styles CSS defines `ontario-header__nav-link--active`)

### Step 2.2: Add Ontario logo to Footer

Add the Ontario trillium logo to the footer, consistent with ODS patterns. The footer typically shows the Ontario logo in the `ontario-footer__logo` area.

Files:

* frontend/src/components/layout/Footer.tsx — Add logo image within the footer container

Key changes:

1. Add `<img>` or inline SVG for the Ontario logo in the footer's top section
2. The logo should link to `https://www.ontario.ca`
3. Add appropriate `alt` text (empty `alt=""` if decorative, or `alt="Ontario"` if informational)

Success criteria:

* Ontario logo visible in footer
* Logo links to ontario.ca
* Proper `alt` attribute on logo image

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 313-316) — Footer mentioned

Dependencies:

* Phase 1 completion (logo assets available from complete-styles package)

## Implementation Phase 3: Alert and Card Structure Fixes

<!-- parallelizable: true -->

### Step 3.1: Fix alert structure in SubmitProgram.tsx (L117–L120)

Update the error alert to use the full ODS sub-element pattern with `ontario-alert__header` and `ontario-alert__body`.

Files:

* frontend/src/pages/SubmitProgram.tsx — L117–L120: restructure alert

Before (L117–L120):

```tsx
<div className="ontario-alert ontario-alert--error" role="alert">
  <div className="ontario-alert__message">
    <p>{submitError}</p>
  </div>
</div>
```

After:

```tsx
<div className="ontario-alert ontario-alert--error" role="alert">
  <div className="ontario-alert__header">
    <h2 className="ontario-alert__header-title">{t('error.title')}</h2>
  </div>
  <div className="ontario-alert__body">
    <p>{submitError}</p>
  </div>
</div>
```

Success criteria:

* Alert renders with visible header section and body section
* `role="alert"` preserved for screen reader announcement
* Uses `t('error.title')` i18n key (created in Phase 4)

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 209-224) — Alert fix pattern

Dependencies:

* Phase 4 Step 4.5 (translation keys) — can implement structure first, key added later in same PR

### Step 3.2: Fix alert and card structure in SubmitConfirmation.tsx (L39–L43, L46–L60)

Update the success alert to use ODS sub-element pattern and wrap card content in `ontario-card__content`.

Files:

* frontend/src/pages/SubmitConfirmation.tsx — L39–L43: alert structure; L46–L60: card content wrapper

Before (alert, L39–L43):

```tsx
<div className="ontario-alert ontario-alert--success" role="status">
  <div className="ontario-alert__message">
    <p>{t('confirmation.successMessage')}</p>
  </div>
</div>
```

After (alert):

```tsx
<div className="ontario-alert ontario-alert--success" role="status">
  <div className="ontario-alert__header">
    <h2 className="ontario-alert__header-title">{t('success.title')}</h2>
  </div>
  <div className="ontario-alert__body">
    <p>{t('confirmation.successMessage')}</p>
  </div>
</div>
```

Before (card, L46–L60):

```tsx
<div className="ontario-card">
  <dl className="ontario-description-list">
    ...
  </dl>
</div>
```

After (card):

```tsx
<div className="ontario-card">
  <div className="ontario-card__content">
    <dl className="ontario-description-list">
      ...
    </dl>
  </div>
</div>
```

Success criteria:

* Success alert renders with header and body sub-elements
* Card content wrapped in `ontario-card__content` div
* `role="status"` preserved on success alert

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 226-244) — Card fix pattern

Dependencies:

* Phase 4 Step 4.5 (translation keys for `success.title`)

### Step 3.3: Fix alert structure and replace inline styles in SearchPrograms.tsx (L82, L109–L121, L129)

Three changes in SearchPrograms: fix alert sub-elements, replace inline styles with ODS grid, wrap table in container.

Files:

* frontend/src/pages/SearchPrograms.tsx — L82: inline style; L109–L121: alert; L129: table

**Change 1: Replace inline styles (L82)**

Before:

```tsx
<div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-end' }}>
```

After:

```tsx
<div className="ontario-row">
  <div className="ontario-columns ontario-small-12 ontario-medium-6">
```

Restructure the search input and button into ODS grid columns. The search input goes in one column, the search/clear buttons go in another.

**Change 2: Fix alert structure (L109–L121)**

Before:

```tsx
<div className="ontario-alert ontario-alert--error" role="alert">
  <div className="ontario-alert__message">
    <p>{error}</p>
  </div>
</div>
```

After:

```tsx
<div className="ontario-alert ontario-alert--error" role="alert">
  <div className="ontario-alert__header">
    <h2 className="ontario-alert__header-title">{t('error.title')}</h2>
  </div>
  <div className="ontario-alert__body">
    <p>{error}</p>
  </div>
</div>
```

**Change 3: Wrap table in container (L129)**

Before:

```tsx
<table className="ontario-table" aria-label={t('search.title')}>
```

After:

```tsx
<div className="ontario-table-container">
  <table className="ontario-table" aria-label={t('search.title')}>
    ...
  </table>
</div>
```

Success criteria:

* No inline `style=` attributes remain in SearchPrograms.tsx
* Search form uses ODS grid classes (`ontario-row`, `ontario-columns`)
* Alert uses `__header` / `__body` sub-elements
* Table wrapped in `ontario-table-container`
* Closing `</div>` for table container added after `</table>`

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 246-265) — Grid and table fix patterns

Dependencies:

* Phase 1 completion (complete-styles CSS defines grid and table-container classes)

## Implementation Phase 4: Accessibility and i18n Remediation

<!-- parallelizable: true -->

### Step 4.1: Add `aria-required="true"` to required form inputs in SubmitProgram.tsx

Add `aria-required="true"` to the three required form inputs: programName, programDescription, and programTypeId. The optional fields (submittedBy, documentUrl) do not get this attribute.

Files:

* frontend/src/pages/SubmitProgram.tsx — input at ~L145, textarea at ~L181, select at ~L217

Add `aria-required="true"` to each of these elements:

```tsx
// programName input (~L145)
<input
  ...
  aria-required="true"
/>

// programDescription textarea (~L181)
<textarea
  ...
  aria-required="true"
/>

// programTypeId select (~L217)
<select
  ...
  aria-required="true"
/>
```

Success criteria:

* Screen readers announce these fields as required
* `aria-required="true"` present on exactly 3 form elements
* No change to validation behavior (existing `required` HTML attribute may also be present)

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 327-338) — WCAG 4.1.2

Dependencies:

* None (independent of other steps)

### Step 4.2: Add `lang` attribute to LanguageToggle button

Add a `lang` attribute to the language toggle button that reflects the target language (the language the button will switch to), per WCAG 3.1.2.

Files:

* frontend/src/components/common/LanguageToggle.tsx — L20–L28: add `lang` prop to `<button>`

Before:

```tsx
<button
  type="button"
  className="ontario-header__language-toggler"
  onClick={handleToggle}
  aria-label={t('language.label')}
>
  {t('language.toggle')}
</button>
```

After:

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

Success criteria:

* Button has `lang="fr"` when current language is English
* Button has `lang="en"` when current language is French
* Screen readers use correct pronunciation for the button text

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 270-280) — WCAG 3.1.2

Dependencies:

* None (independent of other steps)

### Step 4.3: Add `ontario-columns` wrapper to Layout.tsx (L23–L25)

Wrap the `<Outlet />` in an `ontario-columns` container to constrain content width per ODS grid patterns.

Files:

* frontend/src/components/layout/Layout.tsx — L23–L25

Before:

```tsx
<div className="ontario-row">
  <Outlet />
</div>
```

After:

```tsx
<div className="ontario-row">
  <div className="ontario-columns ontario-small-12">
    <Outlet />
  </div>
</div>
```

Success criteria:

* Content area constrained by ODS column grid
* No visual regression in page layout
* `ontario-columns` class receives CSS from `complete-styles` package

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 283-295) — Layout column fix

Dependencies:

* Phase 1 completion (complete-styles defines `ontario-columns`)

### Step 4.4: Add language sync on init and languageChanged event in i18n.ts

Add event listeners to synchronize `document.documentElement.lang` with the i18n language on initialization and on language change. Also add `htmlTag` to the detection order.

Files:

* frontend/src/i18n.ts — After the `.init()` chain (after L25)

Add after the i18n initialization:

```typescript
i18n.on('languageChanged', (lng: string) => {
  document.documentElement.lang = lng;
});

// Set initial lang attribute
if (i18n.isInitialized) {
  document.documentElement.lang = i18n.language;
} else {
  i18n.on('initialized', () => {
    document.documentElement.lang = i18n.language;
  });
}
```

Also update the detection order at L20 to include `htmlTag`:

Before:

```typescript
order: ['querystring', 'localStorage', 'navigator'],
```

After:

```typescript
order: ['querystring', 'localStorage', 'htmlTag', 'navigator'],
```

Success criteria:

* `<html lang="en">` or `<html lang="fr">` set on page load
* `lang` attribute updates when user toggles language
* Detection order includes `htmlTag` for SSR/pre-rendered scenarios

Context references:

* .copilot-tracking/research/2025-07-24-ods-ui-compliance-research.md (Lines 297-311) — i18n sync

Dependencies:

* None (independent of other steps)

### Step 4.5: Add missing translation keys for alert headers in EN and FR locale files

Add `error.title` and `success.title` keys to both translation files. These keys are used by the alert `__header` sub-elements added in Phase 3.

Files:

* frontend/public/locales/en/translation.json — Add keys
* frontend/public/locales/fr/translation.json — Add keys

English keys to add:

```json
{
  "error": {
    "title": "Error"
  },
  "success": {
    "title": "Success"
  }
}
```

French keys to add:

```json
{
  "error": {
    "title": "Erreur"
  },
  "success": {
    "title": "Succès"
  }
}
```

Check existing structure: the `error` key may already exist as an object with other sub-keys. If so, add `title` as a sibling. If `error` is a flat string key, restructure appropriately.

Success criteria:

* `t('error.title')` returns "Error" in English and "Erreur" in French
* `t('success.title')` returns "Success" in English and "Succès" in French
* No existing translation keys broken by the additions

Context references:

* Subagent audit (2026-02-19) — confirmed these keys do not exist

Dependencies:

* None (keys can be added before or after Phase 3 alert structure changes)

## Implementation Phase 5: Validation

<!-- parallelizable: false -->

### Step 5.1: Run full project validation

Execute all validation commands for the frontend project:

```bash
cd frontend
npm run lint
npx tsc --noEmit
npm run build
npm test
```

Verify:

* ESLint reports zero errors
* TypeScript compilation succeeds with no type errors
* Vite production build completes successfully
* All existing tests pass (if any exist)

### Step 5.2: Fix minor validation issues

Iterate on lint errors, TypeScript errors, and build warnings. Apply fixes directly when corrections are straightforward and isolated. Common issues to expect:

* Import ordering lint rules after adding new imports (`useLocation`)
* Unused import cleanup if removing old code
* Missing closing tags from restructured JSX

### Step 5.3: Report blocking issues

When validation failures require changes beyond minor fixes:

* Document the issues and affected files
* Provide the user with next steps
* Recommend additional research and planning rather than inline fixes
* Avoid large-scale refactoring within this phase

## Dependencies

* Node.js and npm
* `@ongov/ontario-design-system-complete-styles@6.0.0` on npm
* Ontario trillium logo SVG (from complete-styles package or ODS CDN)
* Ontario favicon files (from complete-styles package or ODS CDN)
* React Router v6+ (`useLocation` hook)
* i18next (`i18n.on` event API)

## Success Criteria

* `npm run build` completes without errors
* `npm run lint` passes without errors
* `npx tsc --noEmit` reports zero type errors
* All 41/41 ODS BEM classes have CSS definitions at runtime
* All alerts use `__header` / `__body` sub-element structure
* Zero inline `style=` attributes in component JSX
* `aria-required`, `lang`, `aria-current`, and `document.documentElement.lang` all set correctly
* Ontario branding (logo, favicon) replaces placeholder assets
