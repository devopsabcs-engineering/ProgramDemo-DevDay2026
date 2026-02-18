# OPS Program Approval Demo - Copilot Instructions

## Project Overview
This is the Developer Day 2026 demo for the Ontario Public Sector (OPS). It is a
full-stack web application where citizens submit program requests and Ministry
employees review them through an internal portal.

## Tech Stack
- **Frontend:** React with TypeScript, Vite, i18next for EN/FR bilingual support
- **Backend:** Java 17, Spring Boot 3.x, Maven
- **Database:** Azure SQL
- **Cloud:** Azure App Service, Durable Functions, Logic Apps, AI Foundry
- **CI/CD:** GitHub Actions
- **Project Management:** Azure DevOps (User Stories, Test Plans)

## Coding Standards

### General
- All user-facing text must be bilingual (English and French) using i18next keys,
  never hardcoded strings.
- All UI components must meet WCAG 2.2 Level AA accessibility standards.
- All UI must follow the Ontario Design System (https://designsystem.ontario.ca/).
- Use semantic HTML elements (nav, main, section, article, aside, header, footer).
- Every form input must have an associated label and appropriate autocomplete attribute.

### Frontend (React + TypeScript)
- Use functional components with hooks exclusively.
- Use the Ontario Design System CSS classes with BEM naming (e.g., ontario-button,
  ontario-input).
- Minimum touch target size: 24x24 CSS pixels (WCAG 2.5.8).
- Color contrast: minimum 4.5:1 for normal text, 3:1 for large text (WCAG 1.4.3).
- Include aria-labels, aria-describedby, and role attributes where needed.
- Use react-router for navigation with descriptive page titles.
- All forms must include error identification (WCAG 3.3.1) and error suggestions
  (WCAG 3.3.3).

### Backend (Java / Spring Boot)
- Follow RESTful API design conventions.
- Use Spring Data JPA for database access.
- Include input validation on all endpoints (@Valid, @NotNull, @Size).
- Return proper HTTP status codes (200, 201, 400, 404, 500).
- Include request/response DTOs separate from entity classes.
- Use Spring MessageSource for backend bilingual messages.

### Database
- Use Flyway-style versioned migration scripts (V001__, V002__, etc.).
- Table names: lowercase, underscores, singular (e.g., program, program_type).
- Column names: lowercase, underscores (e.g., program_name, created_date).
- Always include: id (PK), created_date, updated_date, created_by columns.

### Testing
- Frontend: Jest + React Testing Library.
- Backend: JUnit 5 + Mockito + Spring Boot Test.
- Target 80% code coverage minimum.
- Include accessibility tests using jest-axe for React components.

### CI/CD
- GitHub Actions workflows in .github/workflows/.
- Validate both backend and frontend on every pull request.
- Include linting, unit tests, and build checks in CI.

### Git Workflow
- Branch naming: feature/{work-item-id}-short-description
- Commit messages: Include AB#{work-item-id} for ADO linking.
- PR descriptions: Include Fixes AB#{work-item-id} to auto-close.

## Repository Layout
- backend/ - Java Spring Boot API
- frontend/ - React TypeScript application
- database/ - SQL migration scripts
- infra/ - Azure Bicep templates
- docs/ - Architecture, data dictionary, design documents
