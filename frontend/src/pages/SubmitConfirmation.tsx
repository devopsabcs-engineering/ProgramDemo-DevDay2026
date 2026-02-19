import { useTranslation } from 'react-i18next';
import { Link, useLocation } from 'react-router-dom';
import type { ProgramResponse } from '../types';

/**
 * Confirmation page displayed after a successful program submission.
 *
 * Shows the reference number, program name, status, and next steps.
 * Data is passed via react-router location state from the submission form.
 */
export function SubmitConfirmation() {
  const { t, i18n } = useTranslation();
  const location = useLocation();
  const program = (location.state as { program?: ProgramResponse })?.program;

  if (!program) {
    return (
      <section aria-labelledby="confirmation-heading">
        <h2 id="confirmation-heading" className="ontario-h2">
          {t('confirmation.title')}
        </h2>
        <p>{t('error.generic')}</p>
        <Link to="/" className="ontario-button ontario-button--secondary">
          {t('confirmation.submitAnother')}
        </Link>
      </section>
    );
  }

  const formattedDate = new Date(program.createdDate).toLocaleDateString(
    i18n.language === 'fr' ? 'fr-CA' : 'en-CA'
  );

  return (
    <section aria-labelledby="confirmation-heading">
      <h2 id="confirmation-heading" className="ontario-h2">
        {t('confirmation.title')}
      </h2>

      <div className="ontario-alert ontario-alert--success" role="status">
        <div className="ontario-alert__header">
          <h3 className="ontario-alert__header-title">
            {t('success.title')}
          </h3>
        </div>
        <div className="ontario-alert__body">
          <p>{t('confirmation.message')}</p>
        </div>
      </div>

      <div className="ontario-card">
        <div className="ontario-card__content">
          <dl className="ontario-description-list">
          <dt>{t('confirmation.referenceNumber')}</dt>
          <dd>{program.id}</dd>

          <dt>{t('confirmation.programName')}</dt>
          <dd>{program.programName}</dd>

          <dt>{t('confirmation.status')}</dt>
          <dd>{t(`status.${program.status}`)}</dd>

          <dt>{t('confirmation.submittedDate')}</dt>
          <dd>{formattedDate}</dd>
          </dl>
        </div>
      </div>

      <h3 className="ontario-h4">{t('confirmation.nextSteps')}</h3>
      <p>{t('confirmation.nextStepsDescription')}</p>

      <div className="ontario-button-group">
        <Link to="/" className="ontario-button ontario-button--secondary">
          {t('confirmation.submitAnother')}
        </Link>
        <Link to="/search" className="ontario-button ontario-button--tertiary">
          {t('confirmation.viewPrograms')}
        </Link>
      </div>
    </section>
  );
}
