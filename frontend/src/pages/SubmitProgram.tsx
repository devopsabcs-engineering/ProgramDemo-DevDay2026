import { useState } from 'react';
import type { FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { createProgram } from '../services/api';
import type { ProgramRequest } from '../types';

/** Program type option for the select dropdown. */
interface ProgramTypeOption {
  id: number;
  labelKey: string;
}

const PROGRAM_TYPES: ProgramTypeOption[] = [
  { id: 1, labelKey: 'programType.1' },
  { id: 2, labelKey: 'programType.2' },
  { id: 3, labelKey: 'programType.3' },
  { id: 4, labelKey: 'programType.4' },
  { id: 5, labelKey: 'programType.5' },
];

/**
 * Citizen-facing program submission form.
 *
 * Uses Ontario Design System form classes, i18next for bilingual labels,
 * and client-side validation with accessible error identification
 * (WCAG 3.3.1 and 3.3.3).
 */
export function SubmitProgram() {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [formData, setFormData] = useState<ProgramRequest>({
    programName: '',
    programDescription: '',
    programTypeId: 0,
    submittedBy: '',
    documentUrl: '',
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);

  /** Validates the form and returns a map of field-level errors. */
  const validate = (): Record<string, string> => {
    const newErrors: Record<string, string> = {};

    if (!formData.programName.trim()) {
      newErrors.programName = t('validation.programNameRequired');
    }
    if (!formData.programDescription.trim()) {
      newErrors.programDescription = t('validation.programDescriptionRequired');
    }
    if (!formData.programTypeId) {
      newErrors.programTypeId = t('validation.programTypeRequired');
    }
    if (
      formData.submittedBy &&
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.submittedBy)
    ) {
      newErrors.submittedBy = t('validation.emailInvalid');
    }

    return newErrors;
  };

  const handleChange = (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
    >
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: name === 'programTypeId' ? Number(value) : value,
    }));
    // Clear the field error when user starts typing
    if (errors[name]) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next[name];
        return next;
      });
    }
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setServerError(null);

    const validationErrors = validate();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setSubmitting(true);
    try {
      const response = await createProgram(formData);
      navigate('/confirmation', { state: { program: response } });
    } catch (err) {
      console.error('Program submission failed:', err);
      setServerError(t('error.generic'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section aria-labelledby="submit-heading">
      <h2 id="submit-heading" className="ontario-h2">
        {t('submit.title')}
      </h2>
      <p className="ontario-lead-statement">{t('submit.description')}</p>

      {serverError && (
        <div className="ontario-alert ontario-alert--error" role="alert">
          <div className="ontario-alert__header">
            <h2 className="ontario-alert__header-title">{t('error.title')}</h2>
          </div>
          <div className="ontario-alert__body">
            <p>{serverError}</p>
          </div>
        </div>
      )}

      <form onSubmit={handleSubmit} noValidate>
        {/* Program Name */}
        <div className="ontario-form-group">
          <label htmlFor="programName" className="ontario-label">
            {t('submit.programName')}{' '}
            <span className="ontario-label__flag">
              ({t('submit.required')})
            </span>
          </label>
          {errors.programName && (
            <span
              className="ontario-error-messaging"
              id="programName-error"
              role="alert"
            >
              {errors.programName}
            </span>
          )}
          <input
            type="text"
            id="programName"
            name="programName"
            className={`ontario-input ${
              errors.programName ? 'ontario-input--error' : ''
            }`}
            value={formData.programName}
            onChange={handleChange}
            placeholder={t('submit.programNamePlaceholder')}
            aria-describedby={
              errors.programName ? 'programName-error' : undefined
            }
            aria-invalid={!!errors.programName}
            aria-required="true"
            autoComplete="off"
            maxLength={200}
          />
        </div>

        {/* Program Description */}
        <div className="ontario-form-group">
          <label htmlFor="programDescription" className="ontario-label">
            {t('submit.programDescription')}{' '}
            <span className="ontario-label__flag">
              ({t('submit.required')})
            </span>
          </label>
          {errors.programDescription && (
            <span
              className="ontario-error-messaging"
              id="programDescription-error"
              role="alert"
            >
              {errors.programDescription}
            </span>
          )}
          <textarea
            id="programDescription"
            name="programDescription"
            className={`ontario-input ontario-textarea ${
              errors.programDescription ? 'ontario-input--error' : ''
            }`}
            value={formData.programDescription}
            onChange={handleChange}
            placeholder={t('submit.programDescriptionPlaceholder')}
            rows={5}
            aria-describedby={
              errors.programDescription
                ? 'programDescription-error'
                : undefined
            }
            aria-invalid={!!errors.programDescription}
            aria-required="true"
          />
        </div>

        {/* Program Type */}
        <div className="ontario-form-group">
          <label htmlFor="programTypeId" className="ontario-label">
            {t('submit.programType')}{' '}
            <span className="ontario-label__flag">
              ({t('submit.required')})
            </span>
          </label>
          {errors.programTypeId && (
            <span
              className="ontario-error-messaging"
              id="programTypeId-error"
              role="alert"
            >
              {errors.programTypeId}
            </span>
          )}
          <select
            id="programTypeId"
            name="programTypeId"
            className={`ontario-input ontario-dropdown ${
              errors.programTypeId ? 'ontario-input--error' : ''
            }`}
            value={formData.programTypeId}
            onChange={handleChange}
            aria-describedby={
              errors.programTypeId ? 'programTypeId-error' : undefined
            }
            aria-invalid={!!errors.programTypeId}
            aria-required="true"
          >
            <option value={0} disabled>
              {t('submit.programTypeSelect')}
            </option>
            {PROGRAM_TYPES.map((pt) => (
              <option key={pt.id} value={pt.id}>
                {t(pt.labelKey)}
              </option>
            ))}
          </select>
        </div>

        {/* Submitted By (Email) */}
        <div className="ontario-form-group">
          <label htmlFor="submittedBy" className="ontario-label">
            {t('submit.submittedBy')}
          </label>
          {errors.submittedBy && (
            <span
              className="ontario-error-messaging"
              id="submittedBy-error"
              role="alert"
            >
              {errors.submittedBy}
            </span>
          )}
          <input
            type="email"
            id="submittedBy"
            name="submittedBy"
            className={`ontario-input ${
              errors.submittedBy ? 'ontario-input--error' : ''
            }`}
            value={formData.submittedBy}
            onChange={handleChange}
            placeholder={t('submit.submittedByPlaceholder')}
            aria-describedby={
              errors.submittedBy ? 'submittedBy-error' : undefined
            }
            aria-invalid={!!errors.submittedBy}
            autoComplete="email"
          />
        </div>

        {/* Document URL */}
        <div className="ontario-form-group">
          <label htmlFor="documentUrl" className="ontario-label">
            {t('submit.documentUrl')}
          </label>
          <input
            type="url"
            id="documentUrl"
            name="documentUrl"
            className="ontario-input"
            value={formData.documentUrl}
            onChange={handleChange}
            placeholder={t('submit.documentUrlPlaceholder')}
            autoComplete="url"
          />
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          className="ontario-button ontario-button--primary"
          disabled={submitting}
        >
          {submitting ? t('submit.submitting') : t('submit.submitButton')}
        </button>
      </form>
    </section>
  );
}
