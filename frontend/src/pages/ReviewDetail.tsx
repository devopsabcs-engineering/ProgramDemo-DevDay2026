import { useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams, Link } from 'react-router-dom';
import { getProgramById } from '../services/api';
import type { ProgramResponse } from '../types';
import { ReviewForm } from '../components/review/ReviewForm';

/**
 * Ministry review detail page.
 *
 * Displays full program details and, for submissions that have not yet
 * been reviewed, shows the approve / reject form. Uses Ontario Design
 * System card and description-list patterns with WCAG 2.2 Level AA
 * compliance.
 */
export function ReviewDetail() {
  const { t, i18n } = useTranslation();
  const { id } = useParams<{ id: string }>();

  const [program, setProgram] = useState<ProgramResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProgram = useCallback(async () => {
    if (!id) return;
    setLoading(true);
    setError(null);
    try {
      const data = await getProgramById(Number(id));
      setProgram(data);
    } catch {
      setError(t('review.detail.error'));
    } finally {
      setLoading(false);
    }
  }, [id, t]);

  useEffect(() => {
    fetchProgram();
  }, [fetchProgram]);

  /** Returns the program type name in the current language. */
  const getTypeName = (p: ProgramResponse) =>
    i18n.language === 'fr' ? p.programTypeNameFr : p.programTypeNameEn;

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString(
      i18n.language === 'fr' ? 'fr-CA' : 'en-CA'
    );

  /** Whether the program can still be reviewed. */
  const canReview =
    program?.status === 'SUBMITTED' || program?.status === 'UNDER_REVIEW';

  /** Called after a successful review submission to refresh the data. */
  const handleReviewComplete = () => {
    fetchProgram();
  };

  /* Loading */
  if (loading) {
    return (
      <section aria-labelledby="review-detail-heading">
        <p role="status" aria-live="polite">
          {t('review.detail.loading')}
        </p>
      </section>
    );
  }

  /* Error */
  if (error || !program) {
    return (
      <section aria-labelledby="review-detail-heading">
        <div className="ontario-alert ontario-alert--error" role="alert">
          <div className="ontario-alert__header">
            <h3 className="ontario-alert__header-title">{t('error.title')}</h3>
          </div>
          <div className="ontario-alert__body">
            <p>{error ?? t('error.notFound')}</p>
          </div>
        </div>
        <Link
          to="/review"
          className="ontario-button ontario-button--secondary"
        >
          {t('review.detail.backToDashboard')}
        </Link>
      </section>
    );
  }

  return (
    <section aria-labelledby="review-detail-heading">
      <Link to="/review" className="ontario-back-to-link">
        ← {t('review.detail.backToDashboard')}
      </Link>

      <h2 id="review-detail-heading" className="ontario-h2">
        {t('review.detail.title')}
      </h2>

      {/* Program Details Card */}
      <div className="ontario-card ontario-card--position--horizontal">
        <div className="ontario-card__content">
          <h3 className="ontario-card__heading">
            {program.programName}
          </h3>

          <dl className="ontario-description-list">
            <dt>{t('review.detail.referenceNumber')}</dt>
            <dd>{program.id}</dd>

            <dt>{t('review.detail.programType')}</dt>
            <dd>{getTypeName(program)}</dd>

            <dt>{t('review.detail.status')}</dt>
            <dd>
              <strong>{t(`status.${program.status}`)}</strong>
            </dd>

            <dt>{t('review.detail.description')}</dt>
            <dd>{program.programDescription}</dd>

            <dt>{t('review.detail.submittedBy')}</dt>
            <dd>{program.submittedBy ?? '—'}</dd>

            <dt>{t('review.detail.submittedDate')}</dt>
            <dd>{formatDate(program.createdDate)}</dd>

            {program.documentUrl && (
              <>
                <dt>{t('review.detail.documentUrl')}</dt>
                <dd>
                  <a
                    href={program.documentUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {program.documentUrl}
                  </a>
                </dd>
              </>
            )}

            {program.reviewedBy && (
              <>
                <dt>{t('review.detail.reviewedBy')}</dt>
                <dd>{program.reviewedBy}</dd>
              </>
            )}

            {program.reviewComments && (
              <>
                <dt>{t('review.detail.reviewComments')}</dt>
                <dd>{program.reviewComments}</dd>
              </>
            )}
          </dl>
        </div>
      </div>

      {/* Review Form (only for reviewable submissions) */}
      {canReview && (
        <ReviewForm
          programId={program.id}
          onReviewComplete={handleReviewComplete}
        />
      )}

      {/* AI Document Summary (shown when the Function App has generated one) */}
      {program.aiSummary && (
        <section aria-labelledby="ai-summary-heading">
          <h2 id="ai-summary-heading" className="ontario-h3">
            {t('review.detail.aiSummaryHeading')}
          </h2>
          <div className="ontario-callout">
            <p className="ontario-callout__body">{program.aiSummary}</p>
            <p className="ontario-hint">{t('review.detail.aiSummaryDisclaimer')}</p>
          </div>
        </section>
      )}

      {/* Already reviewed message */}
      {!canReview && (
        <div
          className={`ontario-alert ${
            program.status === 'APPROVED'
              ? 'ontario-alert--success'
              : 'ontario-alert--warning'
          }`}
          role="status"
        >
          <div className="ontario-alert__header">
            <h3 className="ontario-alert__header-title">
              {t('review.detail.alreadyReviewedTitle')}
            </h3>
          </div>
          <div className="ontario-alert__body">
            <p>
              {t('review.detail.alreadyReviewedMessage', {
                status: t(`status.${program.status}`),
              })}
            </p>
          </div>
        </div>
      )}
    </section>
  );
}
