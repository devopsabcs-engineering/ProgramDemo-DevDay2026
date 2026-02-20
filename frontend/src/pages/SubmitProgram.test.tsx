/**
 * Unit tests for the SubmitProgram form component.
 *
 * Covers:
 * - Renders required form fields
 * - Client-side validation on submit with empty fields
 * - Email format validation
 * - Field error cleared on user input
 * - Successful submission calls API and navigates
 * - Server error banner shown on API failure
 */
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { SubmitProgram } from '../pages/SubmitProgram';

// ------------------------------------------------------------------
// Mocks
// ------------------------------------------------------------------

// i18next — return the translation key as the value so tests are stable
vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}));

// react-router-dom — capture navigate calls
const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual =
    await vi.importActual<typeof import('react-router-dom')>('react-router-dom');
  return { ...actual, useNavigate: () => mockNavigate };
});

// api service
const mockCreateProgram = vi.fn();
vi.mock('../services/api', () => ({
  createProgram: (...args: unknown[]) => mockCreateProgram(...args),
}));

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------

/** Render SubmitProgram wrapped in a MemoryRouter (required for useNavigate). */
function renderForm() {
  return render(
    <MemoryRouter>
      <SubmitProgram />
    </MemoryRouter>
  );
}

// ------------------------------------------------------------------
// Tests
// ------------------------------------------------------------------

describe('SubmitProgram', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders the form heading', () => {
    renderForm();
    expect(screen.getByRole('heading', { level: 2 })).toBeInTheDocument();
  });

  it('renders all required form inputs', () => {
    renderForm();
    expect(screen.getByLabelText(/submit\.programName/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/submit\.programDescription/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/submit\.programType/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /submit\.submitButton/i })).toBeInTheDocument();
  });

  it('shows validation errors when form is submitted with empty required fields', async () => {
    const user = userEvent.setup();
    renderForm();

    await user.click(screen.getByRole('button', { name: /submit\.submitButton/i }));

    await waitFor(() => {
      expect(screen.getByText('validation.programNameRequired')).toBeInTheDocument();
      expect(screen.getByText('validation.programDescriptionRequired')).toBeInTheDocument();
      expect(screen.getByText('validation.programTypeRequired')).toBeInTheDocument();
    });
  });

  it('shows email validation error for an invalid email address', async () => {
    const user = userEvent.setup();
    renderForm();

    await user.type(
      screen.getByLabelText(/submit\.programName/i),
      'My Program'
    );
    await user.type(
      screen.getByLabelText(/submit\.programDescription/i),
      'A description'
    );

    // Select a program type
    await user.selectOptions(
      screen.getByLabelText(/submit\.programType/i),
      '1'
    );

    // Type an invalid email
    await user.type(
      screen.getByLabelText(/submit\.submittedBy/i),
      'not-an-email'
    );

    await user.click(screen.getByRole('button', { name: /submit\.submitButton/i }));

    await waitFor(() => {
      expect(screen.getByText('validation.emailInvalid')).toBeInTheDocument();
    });
  });

  it('clears a field error when the user starts editing that field', async () => {
    const user = userEvent.setup();
    renderForm();

    // Trigger validation errors
    await user.click(screen.getByRole('button', { name: /submit\.submitButton/i }));
    await waitFor(() => {
      expect(screen.getByText('validation.programNameRequired')).toBeInTheDocument();
    });

    // Start typing in the name field — error should disappear
    await user.type(screen.getByLabelText(/submit\.programName/i), 'A');
    await waitFor(() => {
      expect(
        screen.queryByText('validation.programNameRequired')
      ).not.toBeInTheDocument();
    });
  });

  it('calls createProgram and navigates to /confirmation on success', async () => {
    const fakeResponse = {
      id: 42,
      programName: 'My Program',
      programDescription: 'A description',
      programTypeId: 1,
      programTypeNameEn: 'Health',
      programTypeNameFr: 'Santé',
      status: 'SUBMITTED',
      submittedBy: 'test@example.com',
      budget: null,
      createdDate: '2026-02-19T00:00:00',
      updatedDate: '2026-02-19T00:00:00',
    };
    mockCreateProgram.mockResolvedValueOnce(fakeResponse);

    const user = userEvent.setup();
    renderForm();

    await user.type(screen.getByLabelText(/submit\.programName/i), 'My Program');
    await user.type(
      screen.getByLabelText(/submit\.programDescription/i),
      'A description'
    );
    await user.selectOptions(screen.getByLabelText(/submit\.programType/i), '1');
    await user.type(
      screen.getByLabelText(/submit\.submittedBy/i),
      'test@example.com'
    );

    await user.click(screen.getByRole('button', { name: /submit\.submitButton/i }));

    await waitFor(() => {
      expect(mockCreateProgram).toHaveBeenCalledWith(
        expect.objectContaining({
          programName: 'My Program',
          programDescription: 'A description',
          programTypeId: 1,
          submittedBy: 'test@example.com',
        })
      );
      expect(mockNavigate).toHaveBeenCalledWith(
        '/confirmation',
        expect.objectContaining({ state: { program: fakeResponse } })
      );
    });
  });

  it('displays a server error alert when the API call fails', async () => {
    mockCreateProgram.mockRejectedValueOnce(new Error('Network error'));

    const user = userEvent.setup();
    renderForm();

    await user.type(screen.getByLabelText(/submit\.programName/i), 'My Program');
    await user.type(
      screen.getByLabelText(/submit\.programDescription/i),
      'A description'
    );
    await user.selectOptions(screen.getByLabelText(/submit\.programType/i), '1');

    await user.click(screen.getByRole('button', { name: /submit\.submitButton/i }));

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('error.generic');
    });
  });
});
