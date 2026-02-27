import { useTranslation } from 'react-i18next';

/**
 * Bilingual language toggle button (EN/FR).
 *
 * Switches i18next language and updates the document lang attribute
 * to satisfy WCAG 3.1.1 (Language of Page). The button label always
 * shows the *other* language so the user knows what they will switch to.
 */
export function LanguageToggle() {
  const { i18n, t } = useTranslation();

  const handleToggle = () => {
    const newLang = i18n.language === 'en' ? 'fr' : 'en';
    i18n.changeLanguage(newLang);
    document.documentElement.lang = newLang;
  };

  return (
    <button
      type="button"
      className="ontario-header__language-toggler"
      onClick={handleToggle}
      aria-label={t('language.label')}
      lang={i18n.language === 'en' ? 'fr' : 'en'}
    >
      {t('language.toggle')}
    </button>
  );
}
