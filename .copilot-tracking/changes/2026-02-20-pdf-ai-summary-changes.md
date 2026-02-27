<!-- markdownlint-disable-file -->
# Release Changes: PDF Attachment and AI Summarization

**Related Plan**: `2026-02-20-pdf-ai-summary-plan.instructions.md`
**Implementation Date**: 2026-02-20

## Summary

Implemented end-to-end PDF attachment and AI summarization: citizens can upload a PDF on program submission; an Azure Durable Function blob-triggers Document Intelligence text extraction and Azure OpenAI gpt-4o summarization; the summary is persisted via a PATCH callback to the Spring Boot API; ministry reviewers see the summary on the Review Detail page.

## Changes

### Added

* `infra/modules/document-intelligence.bicep` — New Bicep module for Azure AI Document Intelligence (FormRecognizer, S0 SKU, disableLocalAuth: true)
* `infra/modules/openai.bicep` — New Bicep module for Azure OpenAI with gpt-4o GlobalStandard deployment (disableLocalAuth: true)
* `infra/modules/cognitive-services-role-assignment.bicep` — Reusable RBAC module for Cognitive Services accounts, following the existing acr-role-assignment pattern
* `backend/src/main/resources/db/migration/V007__add_ai_summary_to_program.sql` — Idempotent Flyway migration adding `ai_summary NVARCHAR(MAX)` and `ai_summary_generated_date DATETIME2` columns to `program` table
* `backend/src/main/java/.../service/BlobStorageService.java` — Spring service uploading PDFs to `program-documents` Azure Blob Storage container using DefaultAzureCredential
* `backend/src/main/java/.../dto/SummaryCallbackDto.java` — Request DTO for PATCH `/api/programs/{id}/summary` callback from Function App
* `functions/PdfSummarizer/PdfSummarizer.csproj` — .NET 8 isolated worker Function App project
* `functions/PdfSummarizer/Program.cs` — Host builder with IHttpClientFactory and Application Insights
* `functions/PdfSummarizer/PdfSummarizerFunction.cs` — BlobTrigger → Durable orchestrator → AnalyzePdf → SummarizeText → CallbackApi activities
* `functions/PdfSummarizer/local.settings.json` — Local dev settings template (gitignored)
* `functions/PdfSummarizer/host.json` — Functions host config with Durable Task hub name

### Modified

* `infra/modules/storage.bicep` — Added `blobServices` child resource, `program-documents` container (publicAccess: None), and `blobServiceUri` output
* `infra/modules/function-app.bicep` — Added SystemAssigned managed identity, `additionalAppSettings` param, `principalId` output
* `infra/main.bicep` — Added documentIntelligence and openAi module calls; four RBAC role assignments (Storage Blob Data Contributor for backendApp and functionApp, Cognitive Services User and OpenAI User for functionApp); `AZURE_STORAGE_BLOB_SERVICE_URI` backend App Service setting; AI service endpoint settings for Function App
* `backend/pom.xml` — Added `azure-storage-blob:12.28.0`; changed `azure-identity` from `runtime` to compile scope
* `backend/src/main/java/.../model/Program.java` — Added `aiSummary` and `aiSummaryGeneratedDate` JPA fields
* `backend/src/main/java/.../dto/ProgramResponse.java` — Added `aiSummary` field
* `backend/src/main/java/.../service/ProgramService.java` — Added `aiSummary` to `toResponse()` mapper; added `updateDocumentUrl()` and `updateAiSummary()` transactional methods
* `backend/src/main/java/.../controller/ProgramController.java` — Changed POST to accept `multipart/form-data`; injected `BlobStorageService`; added `PATCH /{id}/summary` endpoint
* `backend/src/main/resources/application.yml` — Added Spring multipart config (50 MB / 55 MB); added `azure.storage.blob-service-uri` property with Azurite default for local dev
* `frontend/src/types/index.ts` — Removed `documentUrl` from `ProgramRequest`; added `aiSummary?: string | null` to `ProgramResponse`
* `frontend/src/services/api.ts` — Changed `createProgram()` to use `FormData` with `program` JSON blob and optional `document` file part
* `frontend/src/pages/SubmitProgram.tsx` — Replaced `documentUrl` text URL input with accessible PDF file input; added client-side validation for type and 50 MB size limits; passes `documentFile` to `createProgram()`
* `frontend/src/pages/ReviewDetail.tsx` — Added AI summary section using `ontario-callout` with bilingual heading and disclaimer (renders only when `aiSummary` is non-null)
* `frontend/public/locales/en/translation.json` — Added `common.optional`, `submit.document*` (4 keys), `review.detail.aiSummaryHeading`, `review.detail.aiSummaryDisclaimer`
* `frontend/public/locales/fr/translation.json` — French equivalents for all new i18n keys
* `.github/workflows/ci-cd.yml` — Added `functions-ci` CI job (.NET 8 build); updated `tag` job `needs` to include `functions-ci`; added `build-functions` CD job with dotnet publish and artifact upload
* `.gitignore` — Added `functions/**/local.settings.json` exclusion

### Removed

* None

## Additional or Deviating Changes

* `frontend/src/pages/SubmitProgram.tsx` kept `handleChange` and existing `formData` structure unchanged — only `documentUrl` field removed from initial state; `handleChange` unaffected since file input uses its own dedicated `onChange`
* `ProgramRequest.java` (backend DTO) retained `documentUrl` field for backward compatibility; new multipart submissions from the frontend will not include it, and the blob URL overrides any value set during `createProgram()`
* Function App `CallbackApiActivity` does not use Managed Identity token for the API callback (no `API_CLIENT_ID` enforced) — the Spring Boot PATCH endpoint is unauthenticated internally; API-level auth can be added in a follow-up if the App Service requires authentication

## Release Summary

**Total files affected**: 25
**Files created**: 11 (3 Bicep modules, 1 SQL migration, 2 Java classes, 5 Function App files)
**Files modified**: 14 (2 Bicep, 1 pom.xml, 4 Java, 2 YAML, 2 TypeScript, 2 TSX, 2 JSON locales, 1 gitignore)
**Files removed**: 0

**Infrastructure**: New Azure Document Intelligence and Azure OpenAI Bicep modules deployed as part of the existing resource group; 4 RBAC role assignments using existing managed identities (no new secrets).

**Deployment notes**: V007 Flyway migration runs automatically on next backend startup. `AZURE_STORAGE_BLOB_SERVICE_URI` must be set in the backend App Service app settings (handled by updated Bicep). Function App requires `DOCUMENT_INTELLIGENCE_ENDPOINT`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_DEPLOYMENT`, and `API_BASE_URL` settings (injected by updated Bicep `additionalAppSettings`). Deploy `functions/PdfSummarizer/publish` artifact to the `func-ops-demo-*` Function App.
