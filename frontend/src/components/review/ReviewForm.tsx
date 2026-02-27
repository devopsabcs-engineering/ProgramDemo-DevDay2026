import { useState } from 'react';
import type { FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { reviewProgram } from '../../services/api';
import type { ReviewRequest } from '../../types';

/** Props for the ReviewForm component. */
interface ReviewFormProps {
  /** The ID of the program to review. */
  programId: number;
  /** Callback invoked after a successful review submission. */
  onReviewComplete: () => void;
}

/**
 * Approve / reject form for Ministry reviewers.
 *
 * Collects the reviewer's name, decision (approve or reject), and
 * optional comments. Uses Ontario Design System form and radio button
 * classes with WCAG 2.2 Level AA compliance including aria-required,
 * aria-invalid, and accessible error identification.
 */
export function ReviewForm({ programId, onReviewComplete }: ReviewFormProps) {
  const { t } = useTranslation();

  const [formData, setFormData] = useState<ReviewRequest>({
    status: 'APPROVED',
    reviewedBy: '',
    reviewComments: '',
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);

  /** Validates the form and returns a map of field-level errors. */
  const validate = (): Record<string, string> => {
    const newErrors: Record<string, string> = {};

    if (!formData.reviewedBy.trim()) {
      newErrors.reviewedBy = t('review.form.reviewerRequired');
    }

    if (
      formData.status === 'REJECTED' &&
      (!formData.reviewComments || !formData.reviewComments.trim())
    ) {
      newErrors.reviewComments = t('review.form.commentsRequiredForReject');
    }

    return newErrors;
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next[name];
        return next;
      });
    }
  };

  const handleStatusChange = (status: 'APPROVED' | 'REJECTED') => {
    setFormData((prev) => ({ ...prev, status }));
    // Clear comments error when switching decision
    if (errors.reviewComments) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next.reviewComments;
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
      await reviewProgram(programId, formData);
      onReviewComplete();
    } catch {
      setServerError(t('review.form.submitError'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="ontario-callout">
      <h3 className="ontario-h3" id="review-form-heading">
        {t('review.form.title')}
      </h3>

      {serverError && (
        <div className="ontario-alert ontario-alert--error" role="alert">
          <div className="ontario-alert__header">
            <h4 className="ontario-alert__header-title">{t('error.title')}</h4>
          </div>
          <div className="ontario-alert__body">
            <p>{serverError}</p>
          </div>
        </div>
      )}

      <form
        onSubmit={handleSubmit}
        noValidate
        aria-labelledby="review-form-heading"
      >
        {/* Reviewer Name */}
        <div className="ontario-form-group">
          <label htmlFor="reviewedBy" className="ontario-label">
            {t('review.form.reviewerName')}{' '}
            <span className="ontario-label__flag">
              ({t('submit.required')})
            </span>
          </label>
          {errors.reviewedBy && (
            <span
              className="ontario-error-messaging"
              id="reviewedBy-error"
              role="alert"
            >
              {errors.reviewedBy}
            </span>
          )}
          <input
            type="text"
            id="reviewedBy"
            name="reviewedBy"
            className={`ontario-input ${
              errors.reviewedBy ? 'ontario-input--error' : ''
            }`}
            value={formData.reviewedBy}
            onChange={handleChange}
            placeholder={t('review.form.reviewerPlaceholder')}
            aria-describedby={
              errors.reviewedBy ? 'reviewedBy-error' : undefined
            }
            aria-invalid={!!errors.reviewedBy}
            aria-required="true"
            autoComplete="name"
            maxLength={100}
          />
        </div>

        {/* Decision Radio Buttons */}
        <fieldset className="ontario-fieldset">
          <legend className="ontario-fieldset__legend">
            {t('review.form.decision')}{' '}
            <span className="ontario-label__flag">
              ({t('submit.required')})
            </span>
          </legend>

          <div className="ontario-radios">
            <div className="ontario-radios__item">
              <input
                type="radio"
                id="decision-approve"
                name="status"
                value="APPROVED"
                className="ontario-radios__input"
                checked={formData.status === 'APPROVED'}
                onChange={() => handleStatusChange('APPROVED')}
              />
              <label htmlFor="decision-approve" className="ontario-radios__label">
                {t('review.form.approve')}
              </label>
            </div>

            <div className="ontario-radios__item">
              <input
                type="radio"
                id="decision-reject"
                name="status"
                value="REJECTED"
                className="ontario-radios__input"
                checked={formData.status === 'REJECTED'}
                onChange={() => handleStatusChange('REJECTED')}
              />
              <label htmlFor="decision-reject" className="ontario-radios__label">
                {t('review.form.reject')}
              </label>
            </div>
          </div>
        </fieldset>

        {/* Review Comments */}
        <div className="ontario-form-group">
          <label htmlFor="reviewComments" className="ontario-label">
            {t('review.form.comments')}{' '}
            {formData.status === 'REJECTED' && (
              <span className="ontario-label__flag">
                ({t('submit.required')})
              </span>
            )}
          </label>
          {errors.reviewComments && (
            <span
              className="ontario-error-messaging"
              id="reviewComments-error"
              role="alert"
            >
              {errors.reviewComments}
            </span>
          )}
          <textarea
            id="reviewComments"
            name="reviewComments"
            className={`ontario-input ontario-textarea ${
              errors.reviewComments ? 'ontario-input--error' : ''
            }`}
            value={formData.reviewComments}
            onChange={handleChange}
            placeholder={t('review.form.commentsPlaceholder')}
            rows={4}
            aria-describedby={
              errors.reviewComments ? 'reviewComments-error' : undefined
            }
            aria-invalid={!!errors.reviewComments}
            aria-required={formData.status === 'REJECTED' ? 'true' : undefined}
          />
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          className={`ontario-button ${
            formData.status === 'APPROVED'
              ? 'ontario-button--primary'
              : 'ontario-button--warning'
          }`}
          disabled={submitting}
        >
          {submitting
            ? t('review.form.submitting')
            : formData.status === 'APPROVED'
              ? t('review.form.approveButton')
              : t('review.form.rejectButton')}
        </button>
      </form>
    </div>
  );
}
