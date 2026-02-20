import { useCallback, useEffect, useState } from 'react';
import type { FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { getPrograms } from '../services/api';
import type { ProgramResponse } from '../types';

/**
 * Search and list page for program submissions.
 *
 * Supports filtering by program name via a search input. Results are
 * displayed in an accessible data table with Ontario Design System styling.
 */
export function SearchPrograms() {
  const { t, i18n } = useTranslation();

  const [programs, setPrograms] = useState<ProgramResponse[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPrograms = useCallback(
    async (query?: string) => {
      setLoading(true);
      setError(null);
      try {
        const data = await getPrograms(query || undefined);
        setPrograms(data);
      } catch {
        setError(t('search.error'));
      } finally {
        setLoading(false);
      }
    },
    [t]
  );

  useEffect(() => {
    fetchPrograms();
  }, [fetchPrograms]);

  const handleSearch = (e: FormEvent) => {
    e.preventDefault();
    fetchPrograms(search);
  };

  const handleClear = () => {
    setSearch('');
    fetchPrograms();
  };

  /** Returns the program type name in the current language. */
  const getTypeName = (program: ProgramResponse) =>
    i18n.language === 'fr'
      ? program.programTypeNameFr
      : program.programTypeNameEn;

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString(
      i18n.language === 'fr' ? 'fr-CA' : 'en-CA'
    );

  return (
    <section aria-labelledby="search-heading">
      <h2 id="search-heading" className="ontario-h2">
        {t('search.title')}
      </h2>
      <p className="ontario-lead-statement">{t('search.description')}</p>

      {/* Search Form */}
      <form
        onSubmit={handleSearch}
        className="ontario-search-form"
        role="search"
      >
        <div className="ontario-search-form__input-group">
          <label htmlFor="search-input" className="ontario-label">
            {t('search.title')}
          </label>
          <input
            type="text"
            id="search-input"
            className="ontario-input"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t('search.searchPlaceholder')}
            autoComplete="off"
          />
        </div>
        <div className="ontario-search-form__actions">
          <button
            type="submit"
            className="ontario-button ontario-button--primary"
          >
            {t('search.searchButton')}
          </button>
          {search && (
            <button
              type="button"
              className="ontario-button ontario-button--tertiary"
              onClick={handleClear}
            >
              {t('search.clearButton')}
            </button>
          )}
        </div>
      </form>

      {/* Results */}
      {loading && (
        <p role="status" aria-live="polite">
          {t('search.loading')}
        </p>
      )}

      {error && (
        <div className="ontario-alert ontario-alert--error" role="alert">
          <div className="ontario-alert__header">
            <h2 className="ontario-alert__header-title">{t('error.title')}</h2>
          </div>
          <div className="ontario-alert__body">
            <p>{error}</p>
            <button
              type="button"
              className="ontario-button ontario-button--secondary"
              onClick={() => fetchPrograms(search || undefined)}
            >
              {t('search.retry')}
            </button>
          </div>
        </div>
      )}

      {!loading && !error && programs.length === 0 && (
        <p role="status" aria-live="polite">
          {t('search.noResults')}
        </p>
      )}

      {!loading && !error && programs.length > 0 && (
        <div className="ontario-table-container">
          <table className="ontario-table" aria-label={t('search.title')}>
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
            {programs.map((program) => (
              <tr key={program.id}>
                <td>{program.id}</td>
                <td>{program.programName}</td>
                <td>{getTypeName(program)}</td>
                <td>{t(`status.${program.status}`)}</td>
                <td>{program.submittedBy ?? '—'}</td>
                <td>{formatDate(program.createdDate)}</td>
                <td>
                  <Link
                    to={`/programs/${program.id}`}
                    className="ontario-button ontario-button--tertiary"
                  >
                    {t('search.table.view')}
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
