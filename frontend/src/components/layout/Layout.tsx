import { useTranslation } from 'react-i18next';
import { Outlet } from 'react-router-dom';
import { Header } from './Header';
import { Footer } from './Footer';

/**
 * Page layout wrapper that renders the Ontario Design System
 * header, application sub-header, and footer around the routed
 * page content.
 *
 * Provides a skip-to-content link for keyboard accessibility
 * (WCAG 2.4.1) and wraps content in a semantic main element.
 */
export function Layout() {
  const { t } = useTranslation();

  return (
    <>
      <a href="#main-content" className="ontario-skip-navigation">
        {t('app.skipToContent')}
      </a>
      <Header />

      {/* Application sub-header banner */}
      <div className="ontario-application-header">
        <div className="ontario-application-header__container">
          <h1 className="ontario-application-header__heading">
            {t('header.title')}
          </h1>
          <span className="ontario-application-header__accent" aria-hidden="true"></span>
          <p className="ontario-application-header__subheading">
            {t('header.subtitle')}
          </p>
        </div>
      </div>

      <main id="main-content" className="ontario-main" tabIndex={-1}>
        <div className="ontario-row">
          <div className="ontario-columns ontario-small-12">
            <Outlet />
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
