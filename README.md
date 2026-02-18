---
title: "OPS Program Approval Demo"
description: "Developer Day 2026 demo showcasing how to build a full-stack web application from scratch using GitHub Copilot for the Ontario Public Sector."
ms.date: 2026-02-16
---

## Overview

This repository contains the Developer Day 2026 demo for the Ontario Public Sector (OPS). The goal is to demonstrate how AI, specifically GitHub Copilot, accelerates building a production-ready web application from scratch.

OPS is launching a system that allows citizens of Ontario to submit program requests to the Government of Ontario. Ministry employees review submissions through an internal portal and notify citizens once a decision is made.

## Business Problem

1. Citizens submit a program request through a public-facing portal.
2. A Ministry employee reviews the submission within an internal portal.
3. Once approved or declined, a notification is sent to the citizen.

## Technical Stack

| Layer | Technology |
|-------|------------|
| Front End | React |
| Back End | Java API layer |
| Database | Azure SQL |
| Cloud Services | Azure Durable Functions, App Services, Logic Apps, AI Foundry (mini model), RBAC authentication |
| UI Design | Figma |
| CI/CD | GitHub Actions |
| Security | GitHub Advanced Security (Dependabot, Secret Scanning) |
| Project Management | Azure DevOps (User Stories, Test Plans) |

## Demo Flow

The demo walks through the full development lifecycle, with each role using GitHub Copilot to accelerate their work.

### Planning

- Use M365 Chat to generate high-level user stories (Infrastructure, Backend, Front End, QA).
- Use GitHub Copilot to populate instruction files describing what we are building.
- Use GitHub Copilot to create an architecture diagram for the solution.

### Build

- **Infrastructure:** Pre-deployed Azure resources ready for integration.
- **DBA:** Connect to Azure SQL and load the database schema.
- **Backend Developer:** Pull a user story from Azure DevOps and use Copilot to build a backend solution with at least two APIs.
- **Front-End Developer:** Start from a Figma prototype, apply WCAG and Ontario.ca design assets, and use Copilot to build a local UI MVP.
- **QA:** Improve code coverage, build test plans, and push them to Azure DevOps.
- **DevOps:** Build CI pipelines with GitHub Actions to validate changes.
- **Power Platform:** Integrate workflows and automation (time permitting).

### Showcase

- Deploy the application to a public URL and demonstrate it fully working.
- If time allows, make a live change to show how Copilot handles iterative development.

## Key Features

- All screens are bilingual (English and French).
- Screens follow the [Ontario Design System](https://designsystem.ontario.ca/).
- All screens meet [WCAG 2.2](https://www.w3.org/TR/WCAG22/) accessibility standards.
- Layout follows the [Government of Ontario](https://www.ontario.ca/) template where possible.

## Application Screens

### Public Portal

![Public Portal Mockup](https://github.com/user-attachments/assets/97260422-82e7-4b2a-a869-d7de057c3315)

![Internal Portal Mockup](https://github.com/user-attachments/assets/7e605922-6644-4492-94a0-5875698481c5)

### Citizen Workflow

1. Register or sign in with a MyOntario account (stretch goal).
2. Submit a new program form containing:
   - Program Name
   - Program Description
   - Program Type (dropdown)
3. Optionally upload a supporting document.
4. Review the submission, accept the disclaimer, and submit.

### Ministry Workflow

1. Receive a notification when a new submission arrives.
2. Open the internal portal to review the program and supporting documents.
3. Add comments and approve or reject the submission.
4. The citizen receives a notification with the decision.
5. Optionally generate a confirmation letter for approved programs.

### Search

- Search by program name, with GitHub Copilot building the initial query.
- Add filters such as approval date range, with Copilot updating the query and screen.

## Live Change Demo

To demonstrate how Copilot handles iterative changes, add a new field to the program approval form and ask Copilot to:

1. Redesign the data model.
2. Update the program form UI.
3. Regenerate queries (insert, update, read).
4. Update unit tests.
5. Run accessibility tests.
6. Identify missing French translations.
7. Suggest handling of default values for existing records.
8. Regenerate architecture documents (Data Dictionary, Design Document).

## Lessons Learned from Dry Runs

Each rehearsal surfaces opportunities to streamline the live demo. The items below capture recurring themes so future iterations start from a stronger baseline.

### Use a Dev Container for Consistent Environments

Define a `.devcontainer/devcontainer.json` that includes Java 21, Node 20, Maven, and all required VS Code extensions. This enables one-click setup in GitHub Codespaces and works locally through the **Dev Containers: Open Folder in Container** feature in VS Code (requires Docker Desktop). A reproducible environment eliminates "works on my machine" issues and reduces setup time during the demo.

### Set Up .gitignore Early

Initialize `.gitignore` with combined rules for Java (`target/`, `*.class`), Node/npm (`node_modules/`, `dist/`), and IDE files (`.idea/`, `.vscode/settings.json`) before the first commit. Retroactively cleaning tracked build artifacts wastes demo time and creates noisy diffs.

### Introduce Testing Earlier Than Phase 6

Waiting until a dedicated QA phase to write tests delays feedback on regressions. Add unit tests alongside each feature phase (backend tests with the API, frontend tests with the portal). This keeps coverage incremental, catches issues sooner, and demonstrates a shift-left testing culture during the demo.

### Generate a Research Plan and Talk Track Up Front

Before building, use Copilot to generate a structured research plan that maps each demo phase to time estimates, deliverables, and talking points. A pre-built talk track keeps the live session on pace and ensures no phase is skipped or rushed. Store the plan in `.copilot-tracking/research/` for easy reference.

### Use H2 for Local Development and Testing

Configure a Spring Boot `local` profile with an H2 in-memory database so developers can run and test the backend without an Azure SQL connection. This speeds up the inner development loop and removes cloud dependency during the demo. Reserve Azure SQL integration for the deployed environment.

### Auto-Version with Phase-Aware CI

The CI pipeline should auto-increment the patch version on every merge to `main` and increment the minor version at each phase boundary. For example, database work ships as `v0.3.x`, backend scaffolding as `v0.4.x`, and so on. Automated versioning produces clear release milestones and eliminates manual tagging errors.

### Surface Key Information in GitHub Workflow Summaries

Every GitHub Actions workflow should write relevant output to the **Job Summary** (`$GITHUB_STEP_SUMMARY`). Examples include deployed URLs after a CD run, test pass/fail counts and coverage percentages after CI, and infrastructure resource names after a Bicep deployment. Surfacing this information directly in the GitHub UI reduces context-switching and makes the demo more visible to observers.

