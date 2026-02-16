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

