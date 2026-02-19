import { useTranslation } from 'react-i18next';

/**
 * Ontario Design System footer with government-required links.
 *
 * Displays the Ontario logo, copyright, accessibility, privacy,
 * and terms-of-use links following Ontario government branding standards.
 */
export function Footer() {
  const { t } = useTranslation();

  return (
    <footer className="ontario-footer" role="contentinfo">
      <div className="ontario-row">
        <div className="ontario-footer__logo-container">
          <a href="https://www.ontario.ca" aria-label="Ontario">
            <img
              src="/ontario-logo.svg"
              alt="Ontario"
              width="120"
              height="27"
            />
          </a>
        </div>
        <div className="ontario-footer__container">
          <ul className="ontario-footer__list">
            <li className="ontario-footer__list-item">
              <a
                href="https://www.ontario.ca/page/accessibility"
                className="ontario-footer__link"
              >
                {t('footer.accessibility')}
              </a>
            </li>
            <li className="ontario-footer__list-item">
              <a
                href="https://www.ontario.ca/page/privacy-statement"
                className="ontario-footer__link"
              >
                {t('footer.privacy')}
              </a>
            </li>
            <li className="ontario-footer__list-item">
              <a
                href="https://www.ontario.ca/page/terms-use"
                className="ontario-footer__link"
              >
                {t('footer.terms')}
              </a>
            </li>
          </ul>
          <p className="ontario-footer__copyright">
            {t('footer.copyright')}
          </p>
        </div>
      </div>
    </footer>
  );
}
