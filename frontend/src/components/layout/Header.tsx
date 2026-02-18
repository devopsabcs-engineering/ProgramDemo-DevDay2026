import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { LanguageToggle } from '../common/LanguageToggle';

/**
 * Ontario Design System header with government branding and navigation.
 *
 * Includes the Ontario logo area, navigation links, and a bilingual
 * language toggle button. Follows Ontario DS BEM class conventions.
 */
export function Header() {
  const { t } = useTranslation();

  return (
    <header className="ontario-header" role="banner">
      <div className="ontario-row">
        <div className="ontario-header__container">
          <a href="https://www.ontario.ca" className="ontario-header__logo-container" aria-label="Ontario.ca">
            <span className="ontario-header__logo">Ontario.ca</span>
          </a>
          <LanguageToggle />
        </div>
      </div>
      <div className="ontario-row">
        <nav className="ontario-header__nav" aria-label={t('header.title')}>
          <ul className="ontario-header__nav-list">
            <li className="ontario-header__nav-item">
              <Link to="/" className="ontario-header__nav-link">
                {t('header.nav.submit')}
              </Link>
            </li>
            <li className="ontario-header__nav-item">
              <Link to="/search" className="ontario-header__nav-link">
                {t('header.nav.search')}
              </Link>
            </li>
            <li className="ontario-header__nav-item">
              <Link to="/review" className="ontario-header__nav-link">
                {t('header.nav.review')}
              </Link>
            </li>
          </ul>
        </nav>
      </div>
      <div className="ontario-row">
        <h1 className="ontario-header__heading">{t('header.title')}</h1>
      </div>
    </header>
  );
}
