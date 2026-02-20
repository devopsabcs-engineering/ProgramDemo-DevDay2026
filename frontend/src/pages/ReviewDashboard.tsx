import { useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { getPrograms } from '../services/api';
import type { ProgramResponse, ProgramStatus } from '../types';

/** Filter options for the status dropdown. */
const STATUS_FILTERS: Array<ProgramStatus | 'ALL'> = [
  'ALL',
  'SUBMITTED',
  'UNDER_REVIEW',
  'APPROVED',
  'REJECTED',
];

/**
 * Ministry review dashboard that lists all program submissions.
 *
 * Supports filtering by status and displays results in an accessible
 * ODS data table. Each row links to the detail/review page.
 */
export function ReviewDashboard() {
  const { t, i18n } = useTranslation();

  const [programs, setPrograms] = useState<ProgramResponse[]>([]);
  const [statusFilter, setStatusFilter] = useState<ProgramStatus | 'ALL'>(
    'ALL'
  );
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPrograms = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getPrograms();
      setPrograms(data);
    } catch {
      setError(t('review.dashboard.error'));
    } finally {
      setLoading(false);
    }
  }, [t]);

  useEffect(() => {
    fetchPrograms();
  }, [fetchPrograms]);

  /** Returns the program type name in the current language. */
  const getTypeName = (program: ProgramResponse) =>
    i18n.language === 'fr'
      ? program.programTypeNameFr
      : program.programTypeNameEn;

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString(
      i18n.language === 'fr' ? 'fr-CA' : 'en-CA'
    );

  /** Applies the status filter to the full program list. */
  const filteredPrograms =
    statusFilter === 'ALL'
      ? programs
      : programs.filter((p) => p.status === statusFilter);

  /** Returns a CSS modifier class for the status badge. */
  const getStatusClass = (status: ProgramStatus) => {
    switch (status) {
      case 'APPROVED':
        return 'ontario-badge ontario-badge--success';
      case 'REJECTED':
        return 'ontario-badge ontario-badge--error';
      case 'UNDER_REVIEW':
        return 'ontario-badge ontario-badge--warning';
      default:
        return 'ontario-badge ontario-badge--information';
    }
  };

  return (
    <section aria-labelledby="review-dashboard-heading">
      <h2 id="review-dashboard-heading" className="ontario-h2">
        {t('review.dashboard.title')}
      </h2>
      <p className="ontario-lead-statement">
        {t('review.dashboard.description')}
      </p>

      {/* Status Filter */}
      <div className="ontario-form-group">
        <label htmlFor="status-filter" className="ontario-label">
          {t('review.dashboard.filterLabel')}
        </label>
        <select
          id="status-filter"
          className="ontario-input ontario-dropdown"
          value={statusFilter}
          onChange={(e) =>
            setStatusFilter(e.target.value as ProgramStatus | 'ALL')
          }
        >
          {STATUS_FILTERS.map((status) => (
            <option key={status} value={status}>
              {status === 'ALL'
                ? t('review.dashboard.filterAll')
                : t(`status.${status}`)}
            </option>
          ))}
        </select>
      </div>

      {/* Loading */}
      {loading && (
        <p role="status" aria-live="polite">
          {t('review.dashboard.loading')}
        </p>
      )}

      {/* Error */}
      {error && (
        <div className="ontario-alert ontario-alert--error" role="alert">
          <div className="ontario-alert__header">
            <h3 className="ontario-alert__header-title">{t('error.title')}</h3>
          </div>
          <div className="ontario-alert__body">
            <p>{error}</p>
            <button
              type="button"
              className="ontario-button ontario-button--secondary"
              onClick={fetchPrograms}
            >
              {t('search.retry')}
            </button>
          </div>
        </div>
      )}

      {/* Empty state */}
      {!loading && !error && filteredPrograms.length === 0 && (
        <p role="status" aria-live="polite">
          {t('review.dashboard.noResults')}
        </p>
      )}

      {/* Results table */}
      {!loading && !error && filteredPrograms.length > 0 && (
        <div className="ontario-table-container">
          <table
            className="ontario-table"
            aria-label={t('review.dashboard.title')}
          >
            <thead>
              <tr>
                <th scope="col">{t('search.table.id')}</th>
                <th scope="col">{t('search.table.name')}</th>
                <th scope="col">{t('search.table.type')}</th>
                <th scope="col">{t('search.table.status')}</th>
                <th scope="col">{t('search.table.submittedBy')}</th>
                <th scope="col">{t('search.table.date')}</th>
                <th scope="col">{t('search.table.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredPrograms.map((program) => (
                <tr key={program.id}>
                  <td>{program.id}</td>
                  <td>{program.programName}</td>
                  <td>{getTypeName(program)}</td>
                  <td>
                    <span className={getStatusClass(program.status)}>
                      {t(`status.${program.status}`)}
                    </span>
                  </td>
                  <td>{program.submittedBy ?? '—'}</td>
                  <td>{formatDate(program.createdDate)}</td>
                  <td>
                    <Link
                      to={`/review/${program.id}`}
                      className="ontario-button ontario-button--tertiary"
                    >
                      {t('review.dashboard.reviewButton')}
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
