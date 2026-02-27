# ODS Component CSS Research Findings

**Date:** 2025-07-24
**Status:** Complete

---

## 1. ODS Package Ecosystem on npm

All packages are published under the `@ongov` namespace. The Ontario Design System is a **monorepo** ([github.com/ongov/ontario-design-system](https://github.com/ongov/ontario-design-system)) built with **Lerna** and **pnpm**, using **Stencil** for web components.

### Available Packages

| Package | Latest | Description |
|---------|--------|-------------|
| `@ongov/ontario-design-system-design-tokens` | 7.0.0 | Raw design tokens (colors, fonts, spacing). Base of all packages. |
| `@ongov/ontario-design-system-global-styles` | 7.0.0 | **Foundation only**: grid, typography, spacing, visibility, colors, basic buttons, form-group. No component styles. |
| `@ongov/ontario-design-system-complete-styles` | 7.0.0 | **All styles**: global + all 35+ component SCSS/CSS. CSS-only, framework-agnostic. |
| `@ongov/ontario-design-system-component-library` | 7.0.0 | Stencil Web Components (Shadow DOM). For plain HTML or any non-React/Angular framework. |
| `@ongov/ontario-design-system-component-library-react` | 7.0.0 | React wrapper around the Stencil Web Components. Requires React ^19.2.4 (v7) or ^18.3.0 (v6). |
| `@ongov/ontario-design-system-component-library-angular` | 7.0.0 | Angular wrapper around the Stencil Web Components. |
| `@ongov/ontario-frontend` | 1.1.0 | Jamstack toolkit for Ontario.ca projects. |
| `@ongov/ontario-search` | 1.9.2 | React search bar and autosuggest component. |

### Version Alignment

All core packages share the same version number (6.0.0, 7.0.0, etc.). The project currently uses **v6.0.0** of `global-styles`.

---

## 2. What the Installed Package (`global-styles` v6.0.0) Actually Provides

### File Structure

```text
dist/
├── favicons/          (6 favicon files)
├── fonts/             (Open Sans, Raleway Modified, Courier Prime — all weights)
├── misc/              (ontario-design-system-fonts.css)
├── styles/
│   ├── css/compiled/
│   │   ├── ontario-theme.css       (69.8 KB)
│   │   ├── ontario-theme.css.map
│   │   └── ontario-theme.min.css   (53.4 KB)
│   └── scss/                       (SCSS source files)
└── index.js
```

### CSS Classes Provided (CONFIRMED by extracting from the CSS)

- **Typography:** `.ontario-h1` through `.ontario-h6`, `.ontario-lead-statement`
- **Grid:** `.ontario-row`, `.ontario-column(s)`, `.ontario-small-*`, `.ontario-medium-*`, `.ontario-large-*`, `.ontario-xlarge-*`, `.ontario-xxlarge-*` (12-column grid with push/pull/offset/centered)
- **Spacing:** `.ontario-margin-*`, `.ontario-padding-*` (top/bottom/left/right × 0/4/8/12/16/24/32/40/48/64/80)
- **Colors:** `.ontario-bg-*` (43 background color utilities)
- **Buttons:** `.ontario-button` (basic)
- **Layout:** `.ontario-form-group`
- **Visibility:** `.ontario-hide`, `.ontario-show-for-*`, `.ontario-invisible`, `.ontario-show-for-sr`, `.ontario-show-on-focus`
- **Other:** `.ontario-hr--dark`, `.ontario-end`, `.ontario-opposite`

### CSS Classes **NOT** Provided (confirmed absent)

`.ontario-header`, `.ontario-footer`, `.ontario-alert`, `.ontario-page-alert`, `.ontario-input`, `.ontario-textarea`, `.ontario-table`, `.ontario-card`, `.ontario-label`, `.ontario-checkbox`, `.ontario-radio`, `.ontario-accordion`, `.ontario-callout`, `.ontario-aside`, `.ontario-badge`, `.ontario-blockquote`, `.ontario-dropdown-list`, `.ontario-fieldset`, `.ontario-hint-expander`, `.ontario-hint-text`, `.ontario-icon`, `.ontario-language-toggle`, `.ontario-loading-indicator`, `.ontario-search-box`, `.ontario-step-indicator`, `.ontario-task`, `.ontario-back-to-top`, `.ontario-critical-alert`, `.ontario-date-input`, `.ontario-form-container`

---

## 3. The `complete-styles` Package — The Missing Piece

### What It Provides

The `@ongov/ontario-design-system-complete-styles` package includes **everything in `global-styles` PLUS all component-specific styles**:

```text
dist/
├── assets/            (SVG logos for header/footer supergraphics)
├── scripts/           (JS for header toggle, table sorting)
├── styles/
│   ├── components/    ← 35+ component SCSS files
│   │   ├── ontario-accordion/
│   │   ├── ontario-aside/
│   │   ├── ontario-back-to-top/
│   │   ├── ontario-badge/
│   │   ├── ontario-blockquote/
│   │   ├── ontario-button/
│   │   ├── ontario-callout/
│   │   ├── ontario-card/
│   │   ├── ontario-card-collection/
│   │   ├── ontario-checkbox/
│   │   ├── ontario-critical-alert/
│   │   ├── ontario-date-input/
│   │   ├── ontario-dropdown-list/
│   │   ├── ontario-fieldset/
│   │   ├── ontario-footer/
│   │   ├── ontario-form-container/
│   │   ├── ontario-header/
│   │   ├── ontario-header-menu-tabs/
│   │   ├── ontario-header-overflow-menu/
│   │   ├── ontario-hint-expander/
│   │   ├── ontario-hint-text/
│   │   ├── ontario-icon/
│   │   ├── ontario-input/
│   │   ├── ontario-language-toggle/
│   │   ├── ontario-loading-indicator/
│   │   ├── ontario-page-alert/
│   │   ├── ontario-radio-buttons/
│   │   ├── ontario-search-box/
│   │   ├── ontario-step-indicator/
│   │   ├── ontario-table/
│   │   ├── ontario-task/
│   │   ├── ontario-task-list/
│   │   └── ontario-textarea/
│   ├── css/compiled/
│   │   ├── ontario-theme.css       (71.5 KB — includes ALL component CSS)
│   │   ├── ontario-theme.css.map
│   │   └── ontario-theme.min.css   (54.7 KB)
│   ├── scss/                       (same foundation SCSS as global-styles)
│   ├── styles/                     (additional SCSS: labels, fieldsets, text-inputs, header, slotted-styles)
│   ├── utils/                      (common form elements, error message SCSS)
│   └── global.scss
```

### Dependencies

```json
{
  "@ongov/ontario-design-system-design-tokens": "6.0.0",
  "@ongov/ontario-design-system-global-styles": "6.0.0",
  "@ongov/ontario-design-system-component-library": "6.0.0"
}
```

It internally depends on `global-styles` and `component-library`, combining their SCSS into one compiled output. No peer dependencies on any framework.

### Key Insight

The compiled `ontario-theme.min.css` in `complete-styles` (54.7 KB) has **all component CSS baked in**. It is a drop-in replacement for the `global-styles` version (53.4 KB). The size difference is small because the component styles use compact selectors, but **the content is completely different** — complete-styles includes header, footer, input, table, alert, and all other component classes.

---

## 4. The React Component Library (Web Components Approach)

### How It Works

The `@ongov/ontario-design-system-component-library-react` wraps Stencil Web Components for native React usage. Components use **Shadow DOM** for style encapsulation — their CSS is embedded internally and does not require external stylesheet imports.

### Usage Pattern

```tsx
import { OntarioButton, OntarioHeader, OntarioFooter } from '@ongov/ontario-design-system-component-library-react';

<OntarioHeader type="application" applicationHeaderInfo={{
  title: "My App",
  href: "/",
}} />

<OntarioButton type="primary">Click me!</OntarioButton>

<OntarioFooter type="default" />
```

### Version Compatibility Issue

| React Library Version | Required React Version | Project React Version | Compatible? |
|---|---|---|---|
| 6.0.0 | `^18.3.0` | `^19.2.0` | **No** |
| 7.0.0 | `^19.2.4` | `^19.2.0` | **No** (needs minor bump to ^19.2.4) |

- **v6.0.0** requires React 18, but the project uses React 19.
- **v7.0.0** requires React `^19.2.4`, and the project has `^19.2.0`. Would need a minor version bump.

### Trade-offs

| Factor | Web Components | CSS-only |
|--------|---------------|----------|
| Style handling | Shadow DOM (encapsulated, automatic) | External CSS classes (manual) |
| Refactor effort | **Major** — replace all custom JSX with ODS components | **Minimal** — swap one npm package |
| Customization | Limited (Shadow DOM blocks external CSS) | Full control over HTML/CSS |
| Accessibility | Built-in ARIA handling | Must implement manually |
| i18next integration | Difficult (Shadow DOM slots, not i18next keys) | Natural (text in JSX, i18next works normally) |
| Testing | Shadow DOM complicates queries | Standard React Testing Library works |
| Bundle size | Larger (Stencil runtime + all component JS) | Smaller (CSS only) |

---

## 5. Recommended Approach

### Primary Recommendation: Install `complete-styles` (CSS-only)

**Replace `global-styles` with `complete-styles`** to get all component CSS classes without any refactoring.

#### Installation Command

```bash
cd frontend
npm uninstall @ongov/ontario-design-system-global-styles
npm install @ongov/ontario-design-system-complete-styles@6.0.0
```

#### Import Change

In `src/main.tsx`:

```diff
- import '@ongov/ontario-design-system-global-styles/styles/css/compiled/ontario-theme.min.css';
+ import '@ongov/ontario-design-system-complete-styles/styles/css/compiled/ontario-theme.min.css';
```

#### What This Gets You

- All 35+ component CSS classes (header, footer, alert, input, table, card, label, etc.)
- Same fonts, favicons, grid, typography you already have
- Zero changes to existing React components
- i18next integration remains unchanged
- Testing approach remains unchanged
- Ability to use individual component SCSS files for granular imports if desired

#### SCSS Alternative (If Using Sass)

For granular control, import only the components you need:

```scss
// Import global theme
@use '@ongov/ontario-design-system-complete-styles/styles/scss/theme';

// Import specific components
@use '@ongov/ontario-design-system-complete-styles/styles/components/ontario-header/ontario-header';
@use '@ongov/ontario-design-system-complete-styles/styles/components/ontario-footer/ontario-footer';
@use '@ongov/ontario-design-system-complete-styles/styles/components/ontario-input/ontario-input';
```

### Secondary Option: Web Components (NOT Recommended for This Project)

Using `@ongov/ontario-design-system-component-library-react` would require:

1. Bumping React to `^19.2.4` for v7.0.0 compatibility
2. Rewriting all existing custom React components to use ODS Web Components
3. Reworking the i18next integration (Web Components use slots/attributes, not React children with i18next keys)
4. Changing the testing approach (Shadow DOM complicates DOM queries)
5. Losing fine-grained control over HTML structure and CSS customization

This is a poor fit because:

- The project already has working React components with i18next integration
- Shadow DOM interferes with bilingual text management
- The project needs WCAG 2.2 AA compliance with custom validation patterns already built
- The refactor effort far outweighs the benefits

---

## 6. Summary

| Question | Answer |
|----------|--------|
| Does the installed `global-styles` have component CSS? | **No.** Only grid, typography, spacing, colors, basic buttons. |
| What package has all component CSS? | **`@ongov/ontario-design-system-complete-styles`** |
| Is it a drop-in replacement? | **Yes.** Same CSS file name, same import path structure. |
| Are Web Components needed? | **No.** CSS-only approach works for custom React components. |
| React component library exists? | Yes, but requires React version changes and major refactoring. Not recommended. |
| Install command | `npm install @ongov/ontario-design-system-complete-styles@6.0.0` |
| Import change | Swap `global-styles` → `complete-styles` in the import path in `main.tsx` |

---

## 7. ODS Official Documentation References

- [npm packages guide](https://designsystem.ontario.ca/docs/documentation/develop/npm-packages.html) — explicitly states: *"Most users should be using the complete styles package or one of the component library packages."*
- [Web components guide](https://designsystem.ontario.ca/docs/documentation/develop/web-components.html) — React installation: `npm install --save @ongov/ontario-design-system-component-library-react`
- [Developer docs](https://designsystem.ontario.ca/developer-docs/) — Component API documentation
- [GitHub repo](https://github.com/ongov/ontario-design-system) — Monorepo source code
