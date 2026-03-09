import { StrictMode, Suspense } from 'react';
import { createRoot } from 'react-dom/client';
import './i18n';
import './services/appInsights';
import App from './App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Suspense fallback={<div className="ontario-loading-indicator">Loading… / Chargement…</div>}>
      <App />
    </Suspense>
  </StrictMode>
);
