import { useTranslation } from 'react-i18next';
import { Outlet } from 'react-router-dom';
import { Header } from './Header';
import { Footer } from './Footer';

/**
 * Page layout wrapper that renders the Ontario Design System
 * header and footer around the routed page content.
 *
 * Also provides a skip-to-content link for keyboard accessibility
 * (WCAG 2.4.1) and wraps the content in a semantic main element.
 */
export function Layout() {
  const { t } = useTranslation();

  return (
    <>
      <a href="#main-content" className="ontario-skip-navigation">
        {t('app.skipToContent')}
      </a>
      <Header />
      <main id="main-content" className="ontario-main" tabIndex={-1}>
        <div className="ontario-row">
          <Outlet />
        </div>
      </main>
      <Footer />
    </>
  );
}
