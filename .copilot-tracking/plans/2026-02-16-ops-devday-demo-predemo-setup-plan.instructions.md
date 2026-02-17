---
applyTo: '.copilot-tracking/changes/2026-02-16-ops-devday-demo-predemo-setup-changes.md'
---
<!-- markdownlint-disable-file -->
# Implementation Plan: OPS Developer Day 2026 Pre-Demo Setup

## Overview

Create all pre-demo scaffolding for a 2-hour live coding demo: repository-wide and path-specific Copilot instructions, architecture documents, ADO work items (Epic, Features, User Stories), expanded CI pipeline, and milestone tags so the live demo focuses entirely on Copilot-assisted code generation.

## Objectives

* Commit `.github/copilot-instructions.md` with project context, tech stack, and coding standards.
* Commit four path-specific instruction files (Java, React, SQL, CI/CD).
* Commit `docs/architecture.md`, `docs/data-dictionary.md`, and `docs/design-document.md`.
* Create the full ADO work item hierarchy (1 Epic, 8 Features, ~30 User Stories) with `Agentic AI` tag.
* Expand `.github/workflows/ci.yml` with backend and frontend build/test jobs.
* Add directory placeholders for `database/`, `backend/`, `frontend/`, and `infra/`.
* Tag `v0.1.0` (scaffolding) and `v0.2.0` (architecture and data dictionary).

## Context Summary

### Project Files

* [README.md](../../README.md) - Business problem, tech stack, demo flow, mockups, citizen and ministry workflows.
* [.github/instructions/ado-workflow.instructions.md](../../.github/instructions/ado-workflow.instructions.md) - ADO org/project, hierarchy rules, branching, commit linking, PR workflow.
* [.github/workflows/ci.yml](../../.github/workflows/ci.yml) - Existing CI that auto-tags patch versions on push to main. No build or test steps.
* [.vscode/mcp.json](../../.vscode/mcp.json) - ADO MCP server configuration for Copilot integration.

### References

* [.copilot-tracking/research/2026-02-16-ops-devday-demo-research.md](../research/2026-02-16-ops-devday-demo-research.md) - Full task research with demo schedule, repo structure, ADO hierarchy, tagged commits plan, API and schema docs.
* [.copilot-tracking/subagent/2026-02-16/demo-structure-research.md](../subagent/2026-02-16/demo-structure-research.md) - Detailed subagent research with recommended repo layout, custom instructions content, architecture diagram, data dictionary, WCAG 2.2 checklist, risk mitigations.

### Standards References

* #file:../../.github/instructions/ado-workflow.instructions.md - ADO hierarchy, branching, `Agentic AI` tag, commit linking rules.

## Implementation Checklist

### [x] Implementation Phase 1: Repository Custom Instructions

<!-- parallelizable: true -->

* [x] Step 1.1: Create `.github/copilot-instructions.md` with repository-wide project context, tech stack, coding standards, accessibility rules, and Git workflow.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 15-69)
* [x] Step 1.2: Create `.github/instructions/java.instructions.md` with `applyTo: "backend/**/*.java"` covering Spring Boot 3.x patterns.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 71-95)
* [x] Step 1.3: Create `.github/instructions/react.instructions.md` with `applyTo: "frontend/**/*.tsx,frontend/**/*.ts"` covering Ontario Design System, i18next, WCAG 2.2.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 97-126)
* [x] Step 1.4: Create `.github/instructions/sql.instructions.md` with `applyTo: "database/**/*.sql"` covering Azure SQL conventions.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 128-150)
* [x] Step 1.5: Create `.github/instructions/cicd.instructions.md` with `applyTo: ".github/workflows/**"` covering GitHub Actions conventions.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 152-176)
* [x] Step 1.6: Validate instruction file frontmatter and Markdown lint
  * Run Markdown lint on all new `.instructions.md` files.
  * Verify `applyTo` globs are syntactically correct.

### [x] Implementation Phase 2: Architecture Documents

<!-- parallelizable: true -->

* [x] Step 2.1: Create `docs/architecture.md` with Mermaid architecture diagram showing all system components and data flow.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 180-248)
* [x] Step 2.2: Create `docs/data-dictionary.md` with table definitions, column types, and relationships.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 250-328)
* [x] Step 2.3: Create `docs/design-document.md` with technical decisions, security model, deployment strategy, and bilingual approach.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 330-432)

### [x] Implementation Phase 3: Directory Scaffolding and CI Pipeline

<!-- parallelizable: true -->

* [x] Step 3.1: Create directory placeholders with `.gitkeep` files for `database/migrations/`, `backend/`, `frontend/`, and `infra/`.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 436-460)
* [x] Step 3.2: Expand `.github/workflows/ci.yml` to add placeholder build and test jobs for backend (Maven) and frontend (npm), keeping existing tag job.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 462-536)
* [x] Step 3.3: Validate CI workflow syntax
  * Run `actionlint` or YAML validation on the expanded workflow.

### [x] Implementation Phase 4: ADO Work Items

<!-- parallelizable: false -->

* [x] Step 4.1: Enable Epics backlog level in ADO project settings (if not already enabled).
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 540-550)
* [x] Step 4.2: Create the Epic "OPS Program Approval System" with `Agentic AI` tag.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 552-564)
* [x] Step 4.3: Create 8 Features under the Epic, each with `Agentic AI` tag.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 566-610)
* [x] Step 4.4: Create ~30 User Stories under the Features, each with `Agentic AI` tag.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 612-730)
* [x] Step 4.5: Assign iteration dates to the 3 default iterations ("Sprint 1 - Demo Day" for all demo stories).
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 732-746)

### [x] Implementation Phase 5: Git Commits and Tags

<!-- parallelizable: false -->

* [x] Step 5.1: Stage and commit all scaffolding files (instructions, directory placeholders, CI pipeline) with message `feat: add repo scaffolding and custom instructions AB#{epic-id}`.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 750-768)
* [x] Step 5.2: Tag commit as `v0.1.0` with annotation "Repo scaffolding complete".
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 770-780)
* [x] Step 5.3: Stage and commit architecture docs with message `docs: add architecture, data dictionary, and design document AB#{epic-id}`.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 782-792)
* [x] Step 5.4: Tag commit as `v0.2.0` with annotation "Architecture and data dictionary".
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 794-804)
* [x] Step 5.5: Push all commits and tags to origin.
  * Details: .copilot-tracking/details/2026-02-16-ops-devday-demo-predemo-setup-details.md (Lines 806-816)

### [x] Implementation Phase 6: Validation

<!-- parallelizable: false -->

* [x] Step 6.1: Run full project validation
  * Verify all files exist with correct paths and content.
  * Validate Markdown syntax on all `.md` files.
  * Validate YAML syntax on CI workflow.
  * Confirm `applyTo` frontmatter globs in all instruction files.
* [x] Step 6.2: Verify ADO work items
  * Confirm Epic exists with correct title and tag.
  * Confirm 8 Features are linked to Epic with correct titles and tags.
  * Confirm ~30 User Stories are linked to correct Features with correct titles and tags.
  * Verify iterations are assigned.
* [x] Step 6.3: Verify Git tags
  * Confirm `v0.1.0` and `v0.2.0` tags exist on correct commits.
  * Confirm tags are pushed to remote.
* [x] Step 6.4: Fix minor validation issues
  * Iterate on lint errors, YAML warnings, and missing fields.
  * Apply fixes directly when corrections are straightforward.
* [x] Step 6.5: Report blocking issues
  * Document issues requiring additional research.
  * Provide user with next steps and recommended fixes.

## Dependencies

* Git CLI for commits, tags, and push operations.
* ADO MCP tools (`mcp_ado_wit_create_work_item`, `mcp_ado_wit_add_child_work_items`, `mcp_ado_work_list_iterations`) for work item creation.
* GitHub Actions syntax knowledge for CI pipeline expansion.
* Ontario Design System v6.0.0 NPM package references.
* Mermaid diagram syntax for architecture documentation.

## Success Criteria

* All 5 instruction files exist with correct `applyTo` frontmatter and comprehensive coding standards.
* All 3 architecture documents exist with Mermaid diagrams, table definitions, and technical decisions.
* CI workflow includes backend (Maven) and frontend (npm) build/test placeholder jobs.
* ADO contains 1 Epic, 8 Features, and ~30 User Stories, all tagged `Agentic AI`.
* Git tags `v0.1.0` and `v0.2.0` exist on the correct commits.
* Repository structure matches the monorepo layout from research.
