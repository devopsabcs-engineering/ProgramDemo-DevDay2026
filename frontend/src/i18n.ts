import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import HttpBackend from 'i18next-http-backend';
import LanguageDetector from 'i18next-browser-languagedetector';

i18n
  .use(HttpBackend)
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    fallbackLng: 'en',
    supportedLngs: ['en', 'fr'],
    interpolation: {
      escapeValue: false,
    },
    backend: {
      loadPath: '/locales/{{lng}}/translation.json',
    },
    detection: {
      order: ['querystring', 'localStorage', 'htmlTag', 'navigator'],
      caches: ['localStorage'],
    },
  });

i18n.on('languageChanged', (lng: string) => {
  document.documentElement.lang = lng;
});

if (i18n.isInitialized) {
  document.documentElement.lang = i18n.language;
} else {
  i18n.on('initialized', () => {
    document.documentElement.lang = i18n.language;
  });
}

export default i18n;
