import { StrictMode, Suspense } from 'react';
import { createRoot } from 'react-dom/client';
import '@ongov/ontario-design-system-complete-styles/styles/css/compiled/ontario-theme.min.css';
import './i18n';
import App from './App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Suspense fallback={<div className="ontario-loading-indicator">Loading…</div>}>
      <App />
    </Suspense>
  </StrictMode>
);
