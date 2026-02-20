import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useLocation } from 'react-router-dom';
import { LanguageToggle } from '../common/LanguageToggle';

/**
 * Ontario Design System header matching Ontario.ca visual design.
 *
 * Features a black top bar with the Ontario trillium logo, a search
 * input, language toggle, and a Topics menu button. Below the top bar,
 * a navigation panel drops down when toggled. Follows Ontario DS BEM
 * class conventions and WCAG 2.2 Level AA.
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
      {/* Black top bar */}
      <div className="ontario-header__top-bar">
        <a
          href="https://www.ontario.ca"
          className="ontario-header__logo-container"
          aria-label="Ontario.ca"
        >
          <img
            src="/ontario-logo-white.svg"
            alt={t('header.ontarioLogo')}
            width="140"
            height="36"
          />
        </a>

        <div className="ontario-header__right">
          {/* Search */}
          <div className="ontario-header__search" role="search">
            <label htmlFor="ontario-header-search" className="ontario-label--visually-hidden">
              {t('header.search')}
            </label>
            <input
              type="search"
              id="ontario-header-search"
              className="ontario-header__search-input"
              placeholder=""
              aria-label={t('header.search')}
              autoComplete="off"
            />
            <button
              type="button"
              className="ontario-header__search-button"
              aria-label={t('header.search')}
            >
              <svg className="ontario-header__search-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                <path d="M15.5 14h-.79l-.28-.27A6.471 6.471 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/>
              </svg>
            </button>
          </div>

          <LanguageToggle />

          {/* Topics / Menu toggle */}
          <button
            className="ontario-header__menu-toggler"
            type="button"
            aria-expanded={menuOpen}
            aria-controls="ontario-header-nav-list"
            onClick={() => setMenuOpen((prev) => !prev)}
          >
            <span className="ontario-header__menu-icon" aria-hidden="true">
              <span></span>
              <span></span>
              <span></span>
            </span>
            {t('header.menuToggle')}
          </button>
        </div>
      </div>

      {/* Navigation dropdown */}
      <nav className="ontario-header__nav" aria-label={t('header.title')}>
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
    </header>
  );
}
