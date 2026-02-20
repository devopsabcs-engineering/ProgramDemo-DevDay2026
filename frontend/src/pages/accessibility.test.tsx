/**
 * Accessibility tests using jest-axe (WCAG 2.2 Level AA).
 *
 * Each test renders a component and asserts that axe detects zero
 * accessibility violations. Tests are written against the following
 * components:
 *   - SubmitProgram (citizen submission form)
 *   - Header
 *   - Footer
 */
import { render } from '@testing-library/react';
import { axe } from 'jest-axe';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect, vi } from 'vitest';
import { SubmitProgram } from '../pages/SubmitProgram';
import { Header } from '../components/layout/Header';
import { Footer } from '../components/layout/Footer';

// ------------------------------------------------------------------
// Mocks
// ------------------------------------------------------------------

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}));

vi.mock('react-router-dom', async () => {
  const actual =
    await vi.importActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useNavigate: () => vi.fn(),
  };
});

vi.mock('../services/api', () => ({
  createProgram: vi.fn(),
}));

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------

function wrap(ui: React.ReactElement) {
  return render(<MemoryRouter>{ui}</MemoryRouter>);
}

// ------------------------------------------------------------------
// Tests
// ------------------------------------------------------------------

describe('Accessibility (jest-axe)', () => {
  it('SubmitProgram form has no accessibility violations', async () => {
    const { container } = wrap(<SubmitProgram />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('Header has no accessibility violations', async () => {
    const { container } = wrap(<Header />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('Footer has no accessibility violations', async () => {
    const { container } = render(<Footer />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
