/**
 * Global test setup for Vitest + React Testing Library.
 *
 * - Imports @testing-library/jest-dom matchers (toBeInTheDocument, etc.)
 * - Configures jest-axe matchers for accessibility testing
 */
import '@testing-library/jest-dom';
import { toHaveNoViolations } from 'jest-axe';

// Extend Vitest's expect with jest-axe matchers
expect.extend(toHaveNoViolations);
