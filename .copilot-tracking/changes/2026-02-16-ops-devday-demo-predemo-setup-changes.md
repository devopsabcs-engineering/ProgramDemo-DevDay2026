<!-- markdownlint-disable-file -->
# Release Changes: OPS Developer Day 2026 Pre-Demo Setup

**Related Plan**: 2026-02-16-ops-devday-demo-predemo-setup-plan.instructions.md
**Implementation Date**: 2026-02-16

## Summary

Create all pre-demo scaffolding for a 2-hour live coding demo: repository-wide and path-specific Copilot instructions, architecture documents, ADO work items (Epic, Features, User Stories), expanded CI pipeline, directory placeholders, and milestone tags.

## Changes

### Added

* `.github/copilot-instructions.md` - Repository-wide Copilot instructions with project context, tech stack, coding standards, accessibility rules, and Git workflow
* `.github/instructions/java.instructions.md` - Path-specific instructions for Java/Spring Boot backend code (applyTo: backend/**/*.java)
* `.github/instructions/react.instructions.md` - Path-specific instructions for React/TypeScript frontend code (applyTo: frontend/**/*.tsx,frontend/**/*.ts)
* `.github/instructions/sql.instructions.md` - Path-specific instructions for Azure SQL migration scripts (applyTo: database/**/*.sql)
* `.github/instructions/cicd.instructions.md` - Path-specific instructions for GitHub Actions workflows (applyTo: .github/workflows/**)
* `docs/architecture.md` - Architecture document with Mermaid diagram, component descriptions, data flow, security model, and deployment topology
* `docs/data-dictionary.md` - Data dictionary with ER diagram, table definitions (program, program_type, notification), seed data, and indexes
* `docs/design-document.md` - Design document with technical decisions, security model, deployment strategy, bilingual approach, API design, and error handling
* `database/migrations/.gitkeep` - Directory placeholder for SQL migration scripts
* `backend/.gitkeep` - Directory placeholder for Java Spring Boot API
* `frontend/.gitkeep` - Directory placeholder for React TypeScript application
* `infra/.gitkeep` - Directory placeholder for Azure Bicep templates

### Modified

* `.github/workflows/ci.yml` - Added pull_request trigger, backend-ci job (Java 21/Maven), frontend-ci job (Node.js 20/npm), tag job guarded with push-only condition

### Removed

### ADO Work Items Created (Phase 4)

* Epic 1797 - "OPS Program Approval System" (tagged "Agentic AI")
* Feature 1801 - "Infrastructure Setup" (child of Epic 1797)
* Feature 1798 - "Database Layer" (child of Epic 1797)
* Feature 1803 - "Backend API" (child of Epic 1797)
* Feature 1805 - "Citizen Portal" (child of Epic 1797)
* Feature 1799 - "Ministry Portal" (child of Epic 1797)
* Feature 1802 - "Quality Assurance" (child of Epic 1797)
* Feature 1804 - "CI/CD Pipeline" (child of Epic 1797)
* Feature 1800 - "Live Change Demo" (child of Epic 1797)
* 35 User Stories (IDs 1806-1840) created under Features, all tagged "Agentic AI", assigned to Iteration 1
* 3 iterations assigned to team: Iteration 1, 2, 3

## Additional or Deviating Changes

* Iteration dates could not be set on existing iterations - `mcp_ado_work_create_iterations` only creates new iterations and cannot update existing ones. The 3 default iterations remain without start/end dates. Iteration assignment to stories was completed successfully.
* ADO Priority field supports max value of 4 - Features 5-8 requested priorities 5-8 which were capped to 4 by ADO.

### Git Commits and Tags (Phase 5)

* Commit `32485c8` - `feat: add repo scaffolding and custom instructions AB#1797` (tag: `v0.1.0`)
* Commit `9b48a78` - `docs: add architecture, data dictionary, and design document AB#1797` (tag: `v0.2.0`)
* Both commits and tags pushed to origin

### Validation (Phase 6)

* All 12 added/modified files verified present with non-zero sizes
* CI workflow YAML validated (proper structure, indentation, valid keys)
* All instruction files confirmed with correct `applyTo` frontmatter globs
* Epic 1797 confirmed with 8 child Feature links
* Feature 1803 (Backend API) confirmed with parent Epic 1797 and 5 child User Stories
* Git tags `v0.1.0` and `v0.2.0` verified on correct commits and pushed to remote
* No blocking issues found

## Review Fix Changes (2026-02-16)

Applied fixes for findings identified in 2026-02-16-ops-devday-demo-predemo-setup-review.md.

### Modified

* `.github/workflows/ci.yml` - Fixed workflow-level permissions from `contents: write` to `contents: read`; added job-level `permissions: contents: read` to backend-ci and frontend-ci; added `permissions: contents: write` to tag job only; changed tag job `needs: []` to `needs: [backend-ci, frontend-ci]` with `!failure() && !cancelled()` guard; added `timeout-minutes: 10` to tag job
* `docs/data-dictionary.md` - Added missing audit columns (created_date, updated_date, created_by) to notification table definition and ER diagram per coding standards
* `.github/instructions/cicd.instructions.md` - Updated caching guidance to mention built-in `cache` parameter on setup-java and setup-node as preferred approach alongside explicit actions/cache

## Release Summary

**Total files affected**: 13 (12 added, 1 modified, 0 removed)

**Files created**:

* `.github/copilot-instructions.md` - Repository-wide Copilot instructions (3226 bytes)
* `.github/instructions/java.instructions.md` - Java/Spring Boot instructions (844 bytes)
* `.github/instructions/react.instructions.md` - React/TypeScript instructions (1886 bytes)
* `.github/instructions/sql.instructions.md` - Azure SQL instructions (970 bytes)
* `.github/instructions/cicd.instructions.md` - CI/CD instructions (1034 bytes)
* `docs/architecture.md` - Architecture with Mermaid diagram (5154 bytes)
* `docs/data-dictionary.md` - Data dictionary with ER diagram (4407 bytes)
* `docs/design-document.md` - Design document (7811 bytes)
* `database/migrations/.gitkeep` - Directory placeholder
* `backend/.gitkeep` - Directory placeholder
* `frontend/.gitkeep` - Directory placeholder
* `infra/.gitkeep` - Directory placeholder

**Files modified**:

* `.github/workflows/ci.yml` - Expanded with backend-ci, frontend-ci, and guarded tag jobs (2620 bytes)

**ADO work items**: 1 Epic, 8 Features, 35 User Stories (44 total), all tagged "Agentic AI"

**Git milestones**: `v0.1.0` (scaffolding), `v0.2.0` (architecture docs)

**Known deviations**: Iteration dates not configurable via MCP tools; ADO priority capped at 4

---

## Infrastructure Deployment Changes (2026-02-16)

### Added

* `infra/types.bicep` - Shared Bicep type definitions (DeploymentConfig, SqlConfig, AppServicePlanConfig) with defaults
* `infra/main.bicep` - Main orchestration template deploying all Azure resources via modules
* `infra/main.bicepparam` - Parameter values for dev environment using readEnvironmentVariable for SQL password
* `infra/modules/app-service-plan.bicep` - Linux App Service Plan module
* `infra/modules/web-app.bicep` - Reusable web app module (used for both frontend and backend)
* `infra/modules/sql.bicep` - Azure SQL Server, database, and firewall rules module
* `infra/modules/storage.bicep` - Storage account module for Azure Functions runtime
* `infra/modules/function-app.bicep` - Consumption-plan Function App module for Durable Functions
* `infra/modules/logic-app.bicep` - Consumption Logic App module with HTTP trigger for email notifications
* `.github/workflows/deploy-infra.yml` - Manual-dispatch workflow with validate + deploy jobs using OIDC auth

### Modified

* `.gitignore` - Added `infra/*.json` to ignore compiled ARM template output

### Removed

* `infra/.gitkeep` - Replaced by actual Bicep infrastructure files
