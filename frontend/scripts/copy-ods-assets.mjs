/**
 * Copies Ontario Design System static assets (CSS, favicons) from
 * node_modules into public/ so the Vite dev server can serve them as plain
 * static files.
 *
 * Fonts are loaded from Google Fonts CDN (see index.html) instead of from the
 * ODS package, because the packaged WOFF2/OTF/TTF files trigger OTS parsing
 * errors in modern browsers. The @font-face rules are therefore stripped from
 * the copied CSS.
 *
 * Runs automatically via the "postinstall" npm script.
 */

import { cpSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const frontendDir = resolve(__dirname, '..');
const odsDistDir = resolve(
  frontendDir,
  'node_modules',
  '@ongov',
  'ontario-design-system-complete-styles',
  'dist'
);
const publicDir = resolve(frontendDir, 'public');

// --- Copy compiled CSS (with @font-face rules stripped) ---
// Fonts come from Google Fonts CDN, so remove all @font-face blocks to avoid
// the browser downloading the ODS font files (which fail OTS validation).
console.log('Copying ODS CSS to public/styles/css/compiled/ (stripping @font-face) ...');
const cssDestDir = resolve(publicDir, 'styles', 'css', 'compiled');
mkdirSync(cssDestDir, { recursive: true });

let css = readFileSync(
  resolve(odsDistDir, 'styles', 'css', 'compiled', 'ontario-theme.min.css'),
  'utf8'
);

// Strip all @font-face{...} blocks (handles nested braces gracefully for
// minified CSS where each block is a single-level brace pair).
css = css.replace(/@font-face\{[^}]*\}/g, '');

writeFileSync(resolve(cssDestDir, 'ontario-theme.min.css'), css, 'utf8');

// --- Copy favicons ---
console.log('Copying ODS favicons to public/ ...');
cpSync(resolve(odsDistDir, 'favicons'), resolve(publicDir, 'favicons'), {
  recursive: true,
  force: true,
});
// Also copy favicon.ico to public root for the <link rel="icon"> in index.html
cpSync(
  resolve(odsDistDir, 'favicons', 'favicon.ico'),
  resolve(publicDir, 'favicon.ico'),
  { force: true }
);

console.log('ODS assets copied successfully.');
