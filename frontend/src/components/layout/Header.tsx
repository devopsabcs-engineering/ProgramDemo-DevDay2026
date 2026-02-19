import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useLocation } from 'react-router-dom';
import { LanguageToggle } from '../common/LanguageToggle';

/**
 * Ontario Design System header with government branding and navigation.
 *
 * Includes the Ontario trillium logo, navigation links with active state,
 * a mobile menu toggle, and a bilingual language toggle button.
 * Follows Ontario DS BEM class conventions and WCAG 2.2 Level AA.
 */
export function Header() {
  const { t } = useTranslation();
  const location = useLocation();
  const [menuOpen, setMenuOpen] = useState(false);

  const navItems = [
    { to: '/', label: t('header.nav.submit') },
    { to: '/search', label: t('header.nav.search') },
  ];

  const isActive = (path: string) => {
    if (path === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <header className="ontario-header" role="banner">
      <div className="ontario-row">
        <div className="ontario-header__container">
          <a
            href="https://www.ontario.ca"
            className="ontario-header__logo-container"
            aria-label="Ontario.ca"
          >
            <img
              src="/ontario-logo.svg"
              alt="Ontario"
              className="ontario-header__logo"
              width="180"
              height="40"
            />
          </a>
          <LanguageToggle />
        </div>
      </div>
      <div className="ontario-row">
        <nav className="ontario-header__nav" aria-label={t('header.title')}>
          <button
            className="ontario-header__menu-toggler"
            type="button"
            aria-expanded={menuOpen}
            aria-controls="ontario-header-nav-list"
            onClick={() => setMenuOpen((prev) => !prev)}
          >
            {t('header.menuToggle')}
          </button>
          <ul
            className="ontario-header__nav-list"
            id="ontario-header-nav-list"
            data-open={menuOpen ? 'true' : undefined}
          >
            {navItems.map((item) => {
              const active = isActive(item.to);
              return (
                <li key={item.to} className="ontario-header__nav-item">
                  <Link
                    to={item.to}
                    className={`ontario-header__nav-link${active ? ' ontario-header__nav-link--active' : ''}`}
                    aria-current={active ? 'page' : undefined}
                    onClick={() => setMenuOpen(false)}
                  >
                    {item.label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </div>
      <div className="ontario-row">
        <h1 className="ontario-header__heading">{t('header.title')}</h1>
      </div>
    </header>
  );
}
