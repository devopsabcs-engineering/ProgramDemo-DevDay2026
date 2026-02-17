# Design Document

## Overview

The OPS Program Approval System is a full-stack web application built for the Ontario Public Sector Developer Day 2026 demo. It demonstrates how GitHub Copilot accelerates building a production-ready application from scratch. Citizens submit program requests through a public portal, and Ministry employees review submissions through an internal portal with approval or rejection workflows and automated notifications.

## Technical Decisions

### Frontend Framework

**Choice:** React with TypeScript and Vite

**Rationale:** TypeScript provides strong type safety that improves GitHub Copilot suggestion accuracy. Vite offers fast Hot Module Replacement (HMR) essential for live demo responsiveness. React has the largest ecosystem and best Copilot support among frontend frameworks.

### Backend Framework

**Choice:** Java 21 with Spring Boot 3.x and Maven

**Rationale:** Standard OPS technology stack with excellent Copilot support. Java 21 provides modern features (records, sealed classes, pattern matching). Spring Boot 3.x includes built-in support for RESTful APIs, JPA, validation, and externalized configuration.

### Database

**Choice:** Azure SQL Database

**Rationale:** Fully managed relational database service. Native support for NVARCHAR columns required for bilingual (EN/FR) content storage. Compatible with Spring Data JPA and Flyway migrations.

### Repository Layout

**Choice:** Monorepo (single repository for all components)

**Rationale:** Enables the live demo to run from a single VS Code window without switching repositories. Simplifies cross-component changes and CI/CD pipeline configuration. All code, infrastructure, and documentation coexist for easy navigation.

### Internationalization

**Choice:** i18next with react-i18next

**Rationale:** Industry standard for React internationalization. Supports dynamic language switching without page reload. JSON-based translation files are easy to maintain and extend. Compatible with WCAG 3.1.1 (Language of Page) and 3.1.2 (Language of Parts) requirements.

### Ontario Design System Integration

**Choice:** CSS-only approach via @ongov/ontario-design-system-global-styles NPM package

**Rationale:** Simpler integration than Web Components for a live demo. Provides all required Ontario government styling (header, footer, form elements, typography). BEM naming convention aligns with component-based architecture.

### Accessibility Standard

**Choice:** WCAG 2.2 Level AA compliance

**Rationale:** Ontario government requirement for all public-facing applications. Level AA covers all essential accessibility needs including focus management, touch targets, and form error handling.

## Security Model

| Aspect | Implementation | Details |
|--------|---------------|---------|
| Authentication | Azure RBAC | Azure Active Directory integration for user identity |
| Role: Citizen | Submit and view own submissions | Public portal access with MyOntario account (stretch goal) |
| Role: Ministry Employee | Review, approve, reject submissions | Internal portal access with government credentials |
| Transport Security | HTTPS | Enforced on all Azure App Service endpoints |
| CORS | Origin whitelist | Frontend origin only; no wildcard origins |
| Input Validation | Spring @Valid | All API request bodies validated with Bean Validation annotations |
| Secrets | Azure Key Vault | No secrets stored in code or configuration files |
| Dependency Scanning | GitHub Dependabot | Automated pull requests for vulnerable dependencies |
| Secret Scanning | GitHub Secret Scanning | Prevents accidental secret commits |
| Code Analysis | GitHub Code Scanning | Static analysis for security vulnerabilities |

## Deployment Strategy

### Frontend Deployment

- **Service:** Azure App Service
- **Build:** Vite production build (`npm run build`) produces static assets in `dist/`
- **Runtime:** Static file serving from App Service
- **Configuration:** Environment variables for API endpoint URL

### Backend Deployment

- **Service:** Azure App Service
- **Build:** Maven package (`mvn clean package`) produces JAR file
- **Runtime:** Java 21 on Azure App Service
- **Configuration:** Environment variables for database connection, Azure service endpoints

### Database Deployment

- **Service:** Azure SQL Database (pre-provisioned)
- **Migrations:** Flyway versioned scripts applied at application startup
- **Seed Data:** Initial program types loaded via migration script

### Workflow Orchestration

- **Service:** Azure Durable Functions (Consumption plan)
- **Trigger:** HTTP-triggered from backend API
- **Purpose:** Multi-step approval workflow coordination

### Notifications

- **Service:** Azure Logic Apps
- **Trigger:** Called from Durable Functions
- **Purpose:** Email notifications for submission confirmations and decisions

### AI Integration

- **Service:** Azure AI Foundry (Mini Model)
- **Purpose:** Generate human-readable summaries for decision notifications
- **Integration:** Called from backend API or Durable Functions

## Bilingual Approach

### Frontend

- **Library:** i18next with react-i18next
- **Translation files:** `public/locales/en/translation.json` and `public/locales/fr/translation.json`
- **Language toggle:** UI component switches language dynamically without page reload
- **HTML lang attribute:** Set on `<html>` element and updated on language change (WCAG 3.1.1)
- **Mixed language content:** Use `lang` attribute on individual elements (WCAG 3.1.2)

### Backend

- **Library:** Spring MessageSource
- **Message files:** `resources/messages/messages_en.properties` and `resources/messages/messages_fr.properties`
- **Accept-Language header:** API responses localized based on request header

### Database

- **Text columns:** NVARCHAR type for Unicode support
- **Lookup tables:** Separate `_en` and `_fr` columns for bilingual display names
- **Example:** `program_type` table has `type_name_en` and `type_name_fr` columns

## API Design

### Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | /api/programs | Submit a new program request | Citizen |
| GET | /api/programs | List programs (supports ?search= query) | Citizen, Ministry |
| GET | /api/programs/{id} | Get program details | Citizen (own), Ministry |
| PUT | /api/programs/{id}/review | Approve or reject a program | Ministry |

### Response Format

All API responses use JSON. Error responses follow RFC 7807 ProblemDetail format:

```json
{
  "type": "https://example.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "detail": "Program name must not be empty",
  "instance": "/api/programs"
}
```

### HTTP Status Codes

| Code | Usage |
|------|-------|
| 200 | Successful GET or PUT |
| 201 | Successful POST (resource created) |
| 400 | Validation error or bad request |
| 404 | Resource not found |
| 500 | Internal server error |

## Error Handling

### Backend

- **Global handler:** `@ControllerAdvice` class catches all exceptions
- **Response format:** RFC 7807 ProblemDetail with type, title, status, detail, and instance fields
- **Validation errors:** Return 400 with field-level error details
- **Not found:** Return 404 with descriptive message

### Frontend

- **Component errors:** React Error Boundaries catch and display fallback UI
- **API errors:** Toast notifications for transient errors; inline messages for validation errors
- **Form errors:** Inline error messages per field with WCAG 3.3.1 compliance (error identification in text, not just color)
- **Network errors:** Retry logic with user-friendly error messages
