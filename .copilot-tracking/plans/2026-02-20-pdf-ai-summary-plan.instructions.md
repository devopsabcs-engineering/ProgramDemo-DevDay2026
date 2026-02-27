---
applyTo: '.copilot-tracking/changes/2026-02-20-pdf-ai-summary-changes.md'
---
<!-- markdownlint-disable-file -->
# Implementation Plan: PDF Attachment and AI Summarization

## Overview

Enable citizens to attach a PDF when submitting a program request and automatically generate an AI summary displayed on the ministry Review Detail page using Azure Blob Storage, Azure Document Intelligence, and Azure OpenAI via a blob-triggered Azure Function.

## Objectives

* Allow citizens to upload a PDF (≤ 50 MB) during program submission
* Store the PDF securely in Azure Blob Storage (no public access, Managed Identity auth)
* Trigger an Azure Function on blob creation that calls Document Intelligence + Azure OpenAI gpt-4o to produce a plain-language summary
* Persist the summary to Azure SQL via a PATCH callback to the Spring Boot API
* Display the AI summary on the ministry Review Detail page with an appropriate disclaimer

## Context Summary

### Research Files

* `.copilot-tracking/research/2026-02-20-pdf-ai-summary-research.md` — Full architecture decision, selected approach, implementation details, alternatives considered
* `.copilot-tracking/subagent/2026-02-20/azure-ai-pdf-research.md` — Service-by-service analysis; recommends Assistants API (simplest) but notes Preview status; research recommends GA path for government production
* `.copilot-tracking/subagent/2026-02-20/codebase-analysis.md` — Gap analysis: no file upload UI, no multipart endpoint, no Blob SDK, no blob container in infra, no storage config in application.yml

### Key Gap Findings

* `frontend/src/pages/SubmitProgram.tsx` — No `<input type="file">` exists; plain URL text box only
* `frontend/src/services/api.ts` — `Content-Type: application/json` hardcoded; no FormData path
* `backend/src/main/java/.../controller/ProgramController.java` — JSON-only POST; no multipart
* `backend/pom.xml` — No Azure Blob Storage SDK dependency
* `infra/modules/storage.bicep` — No `program-documents` blob container provisioned
* `infra/main.bicep` — No Document Intelligence or OpenAI resources; no RBAC for Storage Blob Data Contributor
* Database — `document_url NVARCHAR(500)` exists; `ai_summary` column does not exist
* Next available Flyway migration: `V007__` (V001–V006 already applied)

### Reference Repository

* `https://github.com/devopsabcs-engineering/Intelligent-PDF-Summarizer-Dotnet` — Durable Functions pattern: BlobTrigger → AnalyzePdf → SummarizeText → WriteDoc (replaced with HTTP callback)

### Standards References

* #file:../../.github/instructions/java.instructions.md — Spring Boot conventions, DTOs, input validation
* #file:../../.github/instructions/react.instructions.md — Functional components, Ontario Design System, WCAG 2.2
* #file:../../.github/instructions/sql.instructions.md — Flyway migration naming, column naming conventions
* #file:../../.github/copilot-instructions.md — Bilingual (EN/FR), WCAG 2.2 AA, Ontario Design System, 80% coverage target

## Implementation Checklist

### [x] Implementation Phase 1: Infrastructure (Bicep)

<!-- parallelizable: true -->

* [x] Step 1.1: Create `infra/modules/document-intelligence.bicep`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 29-75)
* [x] Step 1.2: Create `infra/modules/openai.bicep`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 77-135)
* [x] Step 1.3: Update `infra/modules/storage.bicep` — add `program-documents` container
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 137-165)
* [x] Step 1.4: Update `infra/main.bicep` — add modules + RBAC assignments + App Service env vars
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 167-250)

### [x] Implementation Phase 2: Database Migration

<!-- parallelizable: true -->

* [x] Step 2.1: Create `backend/src/main/resources/db/migration/V007__add_ai_summary_to_program.sql`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 255-285)

### [x] Implementation Phase 3: Backend — Spring Boot

<!-- parallelizable: true -->

* [x] Step 3.1: Add Azure Blob Storage SDK to `backend/pom.xml`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 290-310)
* [x] Step 3.2: Update `Program.java` entity — add `aiSummary` and `aiSummaryGeneratedDate` fields
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 312-340)
* [x] Step 3.3: Update `ProgramDto.java` / `ProgramResponse.java` — add `aiSummary` field
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 342-360)
* [x] Step 3.4: Create `BlobStorageService.java`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 362-415)
* [x] Step 3.5: Update `ProgramController.java` — multipart POST + new PATCH `/summary` endpoint
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 417-500)
* [x] Step 3.6: Update `ProgramService.java` — `uploadDocument` + `updateAiSummary` methods
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 502-545)
* [x] Step 3.7: Update `application.yml` — multipart config + blob URI property
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 547-570)
* [x] Step 3.8: Update `application-azuresql.yml` — blob service URI
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 572-585)
* [x] Step 3.9: Validate phase — `mvn compile` on backend
  * Run: `cd backend && mvn compile -q`

### [x] Implementation Phase 4: Frontend — React

<!-- parallelizable: true -->

* [x] Step 4.1: Update `frontend/src/pages/SubmitProgram.tsx` — add PDF file input
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 590-660)
* [x] Step 4.2: Update `frontend/src/services/api.ts` — use FormData for program submission
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 662-700)
* [x] Step 4.3: Update `frontend/src/types/index.ts` — add `aiSummary` to `Program` type
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 702-715)
* [x] Step 4.4: Update `frontend/src/pages/ReviewDetail.tsx` — display AI summary section
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 717-770)
* [x] Step 4.5: Add i18n keys to `public/locales/en/translation.json`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 772-800)
* [x] Step 4.6: Add i18n keys to `public/locales/fr/translation.json`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 802-830)
* [x] Step 4.7: Validate phase — `npm run lint` on frontend
  * Run: `cd frontend && npm run lint`

### [x] Implementation Phase 5: Azure Function App (.NET)

<!-- parallelizable: true -->

* [x] Step 5.1: Create `functions/PdfSummarizer/` directory structure and `.csproj`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 835-890)
* [x] Step 5.2: Create `functions/PdfSummarizer/PdfSummarizerFunction.cs` — BlobTrigger + Durable orchestrator
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 892-1010)
* [x] Step 5.3: Create `functions/PdfSummarizer/local.settings.json`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 1012-1045)
* [x] Step 5.4: Create `functions/PdfSummarizer/host.json`
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 1047-1065)

### [x] Implementation Phase 6: CI/CD

<!-- parallelizable: false -->

* [x] Step 6.1: Update `.github/workflows/` to add Functions project build step
  * Details: .copilot-tracking/details/2026-02-20-pdf-ai-summary-details.md (Lines 1070-1120)

### [x] Implementation Phase 7: Validation

<!-- parallelizable: false -->

* [x] Step 7.1: Run full project validation
  * `cd backend && mvn verify -q`
  * `cd frontend && npm run build && npm test -- --watchAll=false`
  * `cd functions/PdfSummarizer && dotnet build`
* [x] Step 7.2: Fix minor validation issues
  * Iterate on lint errors and build warnings; apply straightforward fixes directly
* [x] Step 7.3: Report blocking issues
  * Document issues requiring additional research; provide next steps to user

## Dependencies

* Azure Document Intelligence resource (`Microsoft.CognitiveServices/accounts`, kind `FormRecognizer`, SKU S0)
* Azure OpenAI resource (`Microsoft.CognitiveServices/accounts`, kind `OpenAI`) with `gpt-4o` model deployment
* Azure Blob Storage SDK for Java (`com.azure:azure-storage-blob:12.28.0`)
* Azure Identity SDK for Java (`com.azure:azure-identity:1.14.0`)
* .NET 8 SDK (Azure Functions Isolated Worker)
* `Microsoft.Azure.Functions.Worker.Extensions.DurableTask` NuGet package
* `Azure.AI.FormRecognizer` NuGet package (Document Intelligence)
* `Azure.AI.OpenAI` NuGet package
* `Azure.Identity` NuGet package (Managed Identity)

## Success Criteria

* Citizen form includes a PDF file input (optional) that accepts `.pdf` files only, with bilingual label and hint
* Uploaded PDF is stored in `program-documents/{programId}/{filename}.pdf` blob path with no public access
* Azure Function fires within 30–60 seconds of blob creation, generates an AI summary, and PATCHes it to `/api/programs/{id}/summary`
* Ministry reviewer sees the AI summary in an Ontario Design System callout on the Review Detail page
* All Azure service-to-service communication uses Managed Identity (no secrets or connection strings)
* Backend compiles and passes all existing tests; frontend passes lint and all existing tests
