<!-- markdownlint-disable-file -->
# Implementation Details: PDF Attachment and AI Summarization

## Context Reference

Sources:
* `.copilot-tracking/research/2026-02-20-pdf-ai-summary-research.md` — Architecture decision, selected approach (Blob Trigger + Document Intelligence + OpenAI), code samples
* `.copilot-tracking/subagent/2026-02-20/azure-ai-pdf-research.md` — Service-by-service comparison; GA path chosen for government production
* `.copilot-tracking/subagent/2026-02-20/codebase-analysis.md` — Current gap analysis across backend, frontend, infra, and DB

---

## Implementation Phase 1: Infrastructure (Bicep)

<!-- parallelizable: true -->

### Step 1.1: Create `infra/modules/document-intelligence.bicep`

Create a new Bicep module for Azure Document Intelligence (Cognitive Services, kind `FormRecognizer`, SKU S0).
Use User-Assigned Managed Identity for authentication — no key-based access.

Files:
* `infra/modules/document-intelligence.bicep` — new module

```bicep
@description('Azure region for all resources.')
param location string

@description('Unique resource token to avoid naming collisions.')
param resourceToken string

@description('Resource tags to apply.')
param tags object

resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: 'docintel-${resourceToken}'
  location: location
  tags: tags
  kind: 'FormRecognizer'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'docintel-${resourceToken}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

@description('Document Intelligence endpoint URI.')
output endpoint string = documentIntelligence.properties.endpoint
@description('Resource ID for RBAC assignments.')
output id string = documentIntelligence.id
```

Success criteria:
* Module file exists and passes `az bicep build`
* `disableLocalAuth: true` enforces Managed Identity only

Dependencies:
* None (new file)

---

### Step 1.2: Create `infra/modules/openai.bicep`

Create a Bicep module for Azure OpenAI with a `gpt-4o` model deployment.
Use `disableLocalAuth: true` to enforce Managed Identity.

Files:
* `infra/modules/openai.bicep` — new module

```bicep
@description('Azure region for all resources.')
param location string

@description('Unique resource token.')
param resourceToken string

@description('Resource tags.')
param tags object

@description('Chat model deployment name.')
param chatModelDeploymentName string = 'gpt-4o'

resource openAi 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: 'oai-${resourceToken}'
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'oai-${resourceToken}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource chatDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: openAi
  name: chatModelDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
  }
}

@description('Azure OpenAI endpoint URI.')
output endpoint string = openAi.properties.endpoint
@description('Deployment name for use in Function App config.')
output deploymentName string = chatDeployment.name
@description('Resource ID for RBAC assignments.')
output id string = openAi.id
```

Success criteria:
* Module file exists; `az bicep build` passes
* `gpt-4o` deployment uses `GlobalStandard` SKU with capacity 30

Dependencies:
* None (new file)

---

### Step 1.3: Update `infra/modules/storage.bicep` — add `program-documents` container

Add the `blobServices` child resource and a `program-documents` container with `publicAccess: 'None'`.
The existing storage module already has `allowBlobPublicAccess: false`; the container must inherit this.

Files:
* `infra/modules/storage.bicep` — modified

Add after the existing `storageAccount` resource block:

```bicep
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource programDocumentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'program-documents'
  properties: {
    publicAccess: 'None'
  }
}
```

Add output:

```bicep
@description('Blob service URI for use in application configuration.')
output blobServiceUri string = storageAccount.properties.primaryEndpoints.blob
```

Success criteria:
* `program-documents` container provisioned with no public access
* `blobServiceUri` output available for `main.bicep` to inject into App Service settings

Dependencies:
* Existing `storageAccount` resource in `storage.bicep`

---

### Step 1.4: Update `infra/main.bicep` — add modules + RBAC + App Service env vars

Add four changes to `main.bicep`:
1. Call `document-intelligence.bicep` and `openai.bicep` modules
2. Add four RBAC assignments (Storage Blob Data Contributor, Cognitive Services User, Cognitive Services OpenAI User)
3. Add `AZURE_STORAGE_BLOB_SERVICE_URI` to the backend App Service app settings
4. Add Function App app settings for Document Intelligence and OpenAI endpoints

Files:
* `infra/main.bicep` — modified

Module calls to add:

```bicep
module documentIntelligence 'modules/document-intelligence.bicep' = {
  name: 'documentIntelligence'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
  }
}

module openAi 'modules/openai.bicep' = {
  name: 'openAi'
  params: {
    location: location
    resourceToken: resourceToken
    tags: tags
    chatModelDeploymentName: 'gpt-4o'
  }
}
```

RBAC role assignments to add (use `Microsoft.Authorization/roleAssignments@2022-04-01`):

```bicep
// App Service backend identity → Storage Blob Data Contributor (upload PDFs)
// Principal: backendApp managed identity (already exists on web-app module)
// Role: storage-blob-data-contributor-role-id = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// Function App identity → Storage Blob Data Contributor (blob trigger read)
// Function App identity → Cognitive Services User (Document Intelligence)
//   Role: cognitive-services-user-role-id = 'a97b65f3-24c7-4388-baec-2e87135dc908'
// Function App identity → Cognitive Services OpenAI User (Azure OpenAI)
//   Role: cognitive-services-openai-user-role-id = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
```

App Service backend settings additions:

```bicep
{
  name: 'AZURE_STORAGE_BLOB_SERVICE_URI'
  value: storage.outputs.blobServiceUri
}
```

Function App settings additions:

```bicep
{
  name: 'DOCUMENT_INTELLIGENCE_ENDPOINT'
  value: documentIntelligence.outputs.endpoint
}
{
  name: 'AZURE_OPENAI_ENDPOINT'
  value: openAi.outputs.endpoint
}
{
  name: 'AZURE_OPENAI_DEPLOYMENT'
  value: openAi.outputs.deploymentName
}
{
  name: 'API_BASE_URL'
  value: 'https://${backendApp.outputs.defaultHostname}'
}
```

Success criteria:
* `az bicep build infra/main.bicep` passes with no errors
* All four RBAC assignments use Managed Identity principal IDs (no keys)
* Backend App Service has `AZURE_STORAGE_BLOB_SERVICE_URI` app setting
* Function App has `DOCUMENT_INTELLIGENCE_ENDPOINT`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_DEPLOYMENT`, `API_BASE_URL`

Dependencies:
* Steps 1.1, 1.2, 1.3 complete (modules must exist)

---

## Implementation Phase 2: Database Migration

<!-- parallelizable: true -->

### Step 2.1: Create `V007__add_ai_summary_to_program.sql`

Add `ai_summary NVARCHAR(MAX) NULL` and `ai_summary_generated_date DATETIME2 NULL` columns to the `program` table.
Use idempotent pattern consistent with `V006__ensure_program_budget_column.sql`.

Files:
* `backend/src/main/resources/db/migration/V007__add_ai_summary_to_program.sql` — new file

```sql
-- V007__add_ai_summary_to_program.sql
-- Add AI summary columns to program table for automatic document summarization.

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.program')
      AND name = N'ai_summary'
)
BEGIN
    ALTER TABLE program
        ADD ai_summary NVARCHAR(MAX) NULL;
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.program')
      AND name = N'ai_summary_generated_date'
)
BEGIN
    ALTER TABLE program
        ADD ai_summary_generated_date DATETIME2 NULL;
END;
```

Success criteria:
* Migration file exists with correct `V007__` prefix
* Both columns are nullable (summary is set asynchronously by Function App)
* Idempotent (`IF NOT EXISTS` guard) consistent with V006 pattern

Dependencies:
* V001–V006 must be applied in the target environment before V007 runs

---

## Implementation Phase 3: Backend — Spring Boot

<!-- parallelizable: true -->

### Step 3.1: Add Azure Blob Storage SDK to `backend/pom.xml`

Add `azure-storage-blob` and `azure-identity` dependencies.

Files:
* `backend/pom.xml` — modified (add within `<dependencies>`)

```xml
<dependency>
  <groupId>com.azure</groupId>
  <artifactId>azure-storage-blob</artifactId>
  <version>12.28.0</version>
</dependency>
<dependency>
  <groupId>com.azure</groupId>
  <artifactId>azure-identity</artifactId>
  <version>1.14.0</version>
</dependency>
```

Success criteria:
* `mvn dependency:resolve` completes with no errors
* Both JARs downloaded to local Maven repo

Dependencies:
* None

---

### Step 3.2: Update `Program.java` entity — add AI summary fields

Add `aiSummary` and `aiSummaryGeneratedDate` fields to the `Program` entity.
Map these to the `ai_summary` and `ai_summary_generated_date` columns.

Files:
* `backend/src/main/java/com/ontario/demo/programdemo/model/Program.java` — modified

```java
@Column(name = "ai_summary", columnDefinition = "NVARCHAR(MAX)")
private String aiSummary;

@Column(name = "ai_summary_generated_date")
private java.time.LocalDateTime aiSummaryGeneratedDate;
```

Add getters and setters (`getAiSummary()`, `setAiSummary()`, `getAiSummaryGeneratedDate()`, `setAiSummaryGeneratedDate()`).

Success criteria:
* Entity compiles; `getAiSummary()` and `setAiSummary()` available to service layer

Dependencies:
* Step 2.1 (DB column must exist for JPA validation mode)

---

### Step 3.3: Update DTOs — add `aiSummary` field

Add `aiSummary` to response DTO so the frontend can display the summary.

Files:
* `backend/src/main/java/com/ontario/demo/programdemo/dto/ProgramResponse.java` — modified (add field)
* If a separate `ProgramDto` interface/class exists, update that too

```java
private String aiSummary;
// getter: getAiSummary()
```

Add `aiSummary` to the mapper (wherever `ProgramResponse` is built from `Program`).

Success criteria:
* `GET /api/programs/{id}` response JSON includes `aiSummary` (null when not yet generated)

Dependencies:
* Step 3.2 complete (entity has the field)

---

### Step 3.4: Create `BlobStorageService.java`

Create a Spring service that uploads a `MultipartFile` to the `program-documents` container on Azure Blob Storage
using `DefaultAzureCredential` (Managed Identity in Azure, developer credentials locally).

Files:
* `backend/src/main/java/com/ontario/demo/programdemo/service/BlobStorageService.java` — new file

```java
package com.ontario.demo.programdemo.service;

import com.azure.core.util.BinaryData;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@Service
public class BlobStorageService {

    private static final String CONTAINER_NAME = "program-documents";

    private final BlobServiceClient client;

    public BlobStorageService(
            @Value("${azure.storage.blob-service-uri}") String blobServiceUri) {
        this.client = new BlobServiceClientBuilder()
                .endpoint(blobServiceUri)
                .credential(new DefaultAzureCredentialBuilder().build())
                .buildClient();
    }

    /**
     * Uploads a PDF document for a program submission.
     *
     * @param programId the ID of the program (used as blob folder prefix)
     * @param file      the multipart PDF file
     * @return the full blob URL
     * @throws IOException if reading the file fails
     */
    public String uploadDocument(Long programId, MultipartFile file) throws IOException {
        String originalFilename = file.getOriginalFilename() != null
                ? file.getOriginalFilename().replaceAll("[^a-zA-Z0-9._-]", "_")
                : "document.pdf";
        String blobName = programId + "/" + originalFilename;
        BlobClient blobClient = client
                .getBlobContainerClient(CONTAINER_NAME)
                .getBlobClient(blobName);
        blobClient.upload(BinaryData.fromBytes(file.getBytes()), true);
        return blobClient.getBlobUrl();
    }
}
```

Success criteria:
* Service compiles; `uploadDocument()` returns a non-null URL in integration tests
* No credentials stored — `DefaultAzureCredentialBuilder` only

Dependencies:
* Step 3.1 (SDK on classpath)

---

### Step 3.5: Update `ProgramController.java` — multipart POST + PATCH `/summary` endpoint

Two changes to the controller:
1. Change `POST /api/programs` to accept `multipart/form-data` — `program` part as JSON blob, optional `document` part as PDF
2. Add `PATCH /api/programs/{id}/summary` for the Function App callback

Files:
* `backend/src/main/java/com/ontario/demo/programdemo/controller/ProgramController.java` — modified

Change the `createProgram` method:

```java
@PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
@ResponseStatus(HttpStatus.CREATED)
public ProgramResponse createProgram(
        @RequestPart("program") @Valid ProgramRequest request,
        @RequestPart(value = "document", required = false) MultipartFile document) {
    Program program = programService.createProgram(request);
    if (document != null && !document.isEmpty()) {
        try {
            String url = blobStorageService.uploadDocument(program.getId(), document);
            programService.updateDocumentUrl(program.getId(), url);
            program.setDocumentUrl(url);
        } catch (IOException e) {
            // Log and continue — document upload failure is non-fatal
            log.warn("Failed to upload document for program {}: {}", program.getId(), e.getMessage());
        }
    }
    return programMapper.toResponse(program);
}
```

Add new PATCH endpoint:

```java
@PatchMapping("/{id}/summary")
public ResponseEntity<Void> updateAiSummary(
        @PathVariable Long id,
        @RequestBody @Valid SummaryCallbackDto dto) {
    programService.updateAiSummary(id, dto.getSummary());
    return ResponseEntity.noContent().build();
}
```

Create `SummaryCallbackDto.java` in the `dto` package:

```java
package com.ontario.demo.programdemo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class SummaryCallbackDto {

    @NotBlank
    @Size(max = 10000)
    private String summary;

    public String getSummary() { return summary; }
    public void setSummary(String summary) { this.summary = summary; }
}
```

Success criteria:
* `POST /api/programs` with `multipart/form-data` returns 201 with program JSON
* `PATCH /api/programs/{id}/summary` returns 204 and updates the DB record
* Old JSON-only POST behavior removed (or overloaded if needed for backward compatibility)

Dependencies:
* Step 3.4 (BlobStorageService), Step 3.6 (Service methods)

---

### Step 3.6: Update `ProgramService.java` — add `updateDocumentUrl` and `updateAiSummary`

Add two new service methods to persist the blob URL after upload and store the AI summary from the Function App callback.

Files:
* `backend/src/main/java/com/ontario/demo/programdemo/service/ProgramService.java` — modified

```java
@Transactional
public void updateDocumentUrl(Long id, String documentUrl) {
    Program program = programRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Program not found: " + id));
    program.setDocumentUrl(documentUrl);
    programRepository.save(program);
}

@Transactional
public void updateAiSummary(Long id, String summary) {
    Program program = programRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Program not found: " + id));
    program.setAiSummary(summary);
    program.setAiSummaryGeneratedDate(java.time.LocalDateTime.now());
    programRepository.save(program);
}
```

Success criteria:
* Both methods compile and are called correctly from the controller
* `@Transactional` ensures DB commits on exception rollback

Dependencies:
* Step 3.2 (entity fields)

---

### Step 3.7: Update `application.yml` — multipart config + blob URI

Add Spring multipart configuration and the Azure Storage blob service URI property.

Files:
* `backend/src/main/resources/application.yml` — modified

```yaml
spring:
  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 55MB

azure:
  storage:
    blob-service-uri: ${AZURE_STORAGE_BLOB_SERVICE_URI:http://localhost:10000/devstoreaccount1}
```

The default value `http://localhost:10000/devstoreaccount1` is the Azurite local emulator endpoint, allowing local development without Azure credentials.

Success criteria:
* `application.yml` parses correctly; `@Value("${azure.storage.blob-service-uri}")` resolves in `BlobStorageService`

Dependencies:
* Step 3.4 (BlobStorageService needs the property)

---

### Step 3.8: Update `application-azuresql.yml` — Azure environment blob URI

In the Azure environment profile, the blob service URI comes from the `AZURE_STORAGE_BLOB_SERVICE_URI` environment variable injected by the Azure App Service app setting (Step 1.4).
No change needed to `application-azuresql.yml` since the default `${AZURE_STORAGE_BLOB_SERVICE_URI}` in `application.yml` handles it — confirm the profile does not need overrides.

Files:
* `backend/src/main/resources/application-azuresql.yml` — review only; no change expected

Success criteria:
* `AZURE_STORAGE_BLOB_SERVICE_URI` env var is picked up correctly in Azure environment

Dependencies:
* Step 1.4 (App Service app setting injected)

---

## Implementation Phase 4: Frontend — React

<!-- parallelizable: true -->

### Step 4.1: Update `SubmitProgram.tsx` — add PDF file input

Replace the `documentUrl` text-URL input with an `<input type="file" accept=".pdf">` using Ontario Design System classes.
Remove the `documentUrl` field from the form state and add `documentFile: File | null`.

Files:
* `frontend/src/pages/SubmitProgram.tsx` — modified

Key changes:

```tsx
// State
const [documentFile, setDocumentFile] = useState<File | null>(null);

// Remove documentUrl from formData state

// File input JSX (Ontario Design System):
<div className="ontario-form-group">
  <label className="ontario-label" htmlFor="document">
    {t('submit.document')}
    <span className="ontario-label__flag">{t('common.optional')}</span>
  </label>
  <p id="document-hint" className="ontario-hint">
    {t('submit.documentHint')}
  </p>
  <input
    className="ontario-input"
    type="file"
    id="document"
    name="document"
    accept=".pdf"
    aria-describedby="document-hint"
    onChange={(e) => {
      const file = e.target.files?.[0] ?? null;
      if (file && file.type !== 'application/pdf') {
        setErrors(prev => ({ ...prev, document: t('submit.documentErrorType') }));
        setDocumentFile(null);
      } else if (file && file.size > 50 * 1024 * 1024) {
        setErrors(prev => ({ ...prev, document: t('submit.documentErrorSize') }));
        setDocumentFile(null);
      } else {
        setErrors(prev => ({ ...prev, document: undefined }));
        setDocumentFile(file);
      }
    }}
  />
  {errors.document && (
    <p className="ontario-error-text" role="alert">{errors.document}</p>
  )}
</div>

// On submit, pass documentFile to api:
await submitProgram(formData, documentFile ?? undefined);
```

Also remove `documentUrl` from `ProgramRequest` shape passed to `submitProgram`.

Success criteria:
* File input renders with Ontario Design System styling
* `.pdf` files accepted; non-PDF and files > 50 MB show inline error messages
* Form is accessible: label linked by `htmlFor`, hint linked by `aria-describedby`, errors use `role="alert"`
* Bilingual labels use i18n keys

Dependencies:
* Step 4.5 and 4.6 (i18n keys must exist)

---

### Step 4.2: Update `api.ts` — use FormData for program submission

Change `submitProgram` (or `createProgram`) to use `FormData` with a `program` JSON blob part and optional `document` file part.

Files:
* `frontend/src/services/api.ts` — modified

```ts
export async function submitProgram(
  data: ProgramFormData,
  document?: File
): Promise<Program> {
  const form = new FormData();
  form.append(
    'program',
    new Blob([JSON.stringify(data)], { type: 'application/json' })
  );
  if (document) {
    form.append('document', document);
  }
  const response = await apiClient.post<Program>('/programs', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return response.data;
}
```

Remove `documentUrl` from `ProgramFormData` type (or mark it `never`) — the URL is now determined by the server after blob upload.

Success criteria:
* POST sends `multipart/form-data` with `program` and optional `document` parts
* No `Content-Type: application/json` header override when using FormData

Dependencies:
* Step 3.5 (backend endpoint must accept multipart)

---

### Step 4.3: Update `types/index.ts` — add `aiSummary` to `Program` type

Add the `aiSummary` field to the `Program` (response) interface.

Files:
* `frontend/src/types/index.ts` — modified

```ts
export interface Program {
  // existing fields...
  aiSummary?: string | null;
}
```

Remove `documentUrl` from `ProgramRequest` interface (it is now handled server-side).

Success criteria:
* TypeScript compiles with no type errors after adding the field
* `aiSummary` is optional so existing programs without summaries render correctly

Dependencies:
* None

---

### Step 4.4: Update `ReviewDetail.tsx` — display AI summary section

Show the AI summary in an Ontario Design System callout block below the existing program details.
Only render the section when `program.aiSummary` is non-empty.

Files:
* `frontend/src/pages/ReviewDetail.tsx` — modified

```tsx
{program.aiSummary && (
  <section aria-labelledby="ai-summary-heading">
    <h2 id="ai-summary-heading" className="ontario-h3">
      {t('review.aiSummary')}
    </h2>
    <div className="ontario-callout">
      <p className="ontario-callout__body">{program.aiSummary}</p>
      <p className="ontario-hint">{t('review.aiSummaryDisclaimer')}</p>
    </div>
  </section>
)}
```

Success criteria:
* Section does not render when `aiSummary` is null or undefined
* Summary is wrapped in an `ontario-callout` container with a disclaimer
* Section has `aria-labelledby` pointing to a heading ID (WCAG 2.4.6)
* Bilingual heading and disclaimer use i18n keys

Dependencies:
* Step 4.3 (type), Step 4.5 and 4.6 (i18n keys)

---

### Step 4.5: Add i18n keys to `public/locales/en/translation.json`

Add new keys for the file upload field and AI summary section.

Files:
* `frontend/public/locales/en/translation.json` — modified

New keys to add in the `submit` namespace section:

```json
"submit.document": "Supporting Document (PDF)",
"submit.documentHint": "Attach a PDF document to help reviewers understand your program. Maximum 50 MB.",
"submit.documentErrorType": "Only PDF files are accepted. Please select a .pdf file.",
"submit.documentErrorSize": "File size exceeds 50 MB. Please attach a smaller PDF."
```

New keys in the `review` section:

```json
"review.aiSummary": "AI Document Summary",
"review.aiSummaryDisclaimer": "This summary was generated automatically by AI. Verify important details in the attached document."
```

Success criteria:
* Keys follow existing naming convention in the file
* All four `submit.*` keys and two `review.*` keys present

Dependencies:
* None

---

### Step 4.6: Add i18n keys to `public/locales/fr/translation.json`

Mirror the English keys with French translations.

Files:
* `frontend/public/locales/fr/translation.json` — modified

```json
"submit.document": "Document justificatif (PDF)",
"submit.documentHint": "Joignez un document PDF pour aider les examinateurs à comprendre votre programme. Maximum 50 Mo.",
"submit.documentErrorType": "Seuls les fichiers PDF sont acceptés. Veuillez sélectionner un fichier .pdf.",
"submit.documentErrorSize": "La taille du fichier dépasse 50 Mo. Veuillez joindre un fichier PDF plus petit."
```

French review keys:

```json
"review.aiSummary": "Résumé du document par IA",
"review.aiSummaryDisclaimer": "Ce résumé a été généré automatiquement par l'IA. Vérifiez les informations importantes dans le document joint."
```

Success criteria:
* All keys have French equivalents; no English text in FR file
* Values grammatically correct Canadian French

Dependencies:
* None

---

## Implementation Phase 5: Azure Function App (.NET)

<!-- parallelizable: true -->

### Step 5.1: Create `functions/PdfSummarizer/` project structure

Create a .NET 8 isolated worker Function App project targeting `net8.0`.

Files:
* `functions/PdfSummarizer/PdfSummarizer.csproj` — new file
* `functions/PdfSummarizer/` — new directory

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <AzureFunctionsVersion>v4</AzureFunctionsVersion>
    <OutputType>Exe</OutputType>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Azure.Functions.Worker" Version="1.23.0" />
    <PackageReference Include="Microsoft.Azure.Functions.Worker.Extensions.Http" Version="3.2.0" />
    <PackageReference Include="Microsoft.Azure.Functions.Worker.Extensions.Storage.Blobs" Version="6.6.1" />
    <PackageReference Include="Microsoft.Azure.Functions.Worker.Extensions.DurableTask" Version="1.1.6" />
    <PackageReference Include="Microsoft.Azure.Functions.Worker.Sdk" Version="1.17.4" OutputItemType="Analyzer" />
    <PackageReference Include="Azure.AI.FormRecognizer" Version="4.1.0" />
    <PackageReference Include="Azure.AI.OpenAI" Version="2.1.0" />
    <PackageReference Include="Azure.Identity" Version="1.13.1" />
    <PackageReference Include="Microsoft.Extensions.Http" Version="8.0.1" />
  </ItemGroup>
</Project>
```

Create `functions/PdfSummarizer/Program.cs`:

```csharp
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();
        services.AddHttpClient();
    })
    .Build();

await host.RunAsync();
```

Success criteria:
* `dotnet build functions/PdfSummarizer/` succeeds with no errors
* Project targets `net8.0` isolated worker model

Dependencies:
* .NET 8 SDK installed in build environment

---

### Step 5.2: Create `PdfSummarizerFunction.cs` — BlobTrigger + Durable orchestrator

Implement the three-activity Durable Functions pipeline adapted from the reference repository.
Replace the `WriteDoc` activity with an HTTP callback PATCH to the Spring Boot API.

Files:
* `functions/PdfSummarizer/PdfSummarizerFunction.cs` — new file

```csharp
using Azure;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.DurableTask.Client;
using Microsoft.Extensions.Logging;
using OpenAI.Chat;
using System.Net.Http.Json;

namespace PdfSummarizer;

public record PdfSummaryInput(string ProgramId, string BlobUrl);
public record SummaryCallbackPayload(string Summary);

public class PdfSummarizerFunction
{
    // ── Blob Trigger ──────────────────────────────────────────────────────────
    [Function(nameof(TriggerProcessDocument))]
    public async Task TriggerProcessDocument(
        [BlobTrigger("program-documents/{programId}/{name}",
            Connection = "AzureWebJobsStorage")] Stream pdfStream,
        string programId,
        string name,
        Uri blobUri,
        [DurableClient] DurableTaskClient starter,
        FunctionContext context)
    {
        var logger = context.GetLogger(nameof(TriggerProcessDocument));
        logger.LogInformation("Blob trigger fired for program {ProgramId}, blob {Name}", programId, name);

        string instanceId = await starter.ScheduleNewOrchestrationInstanceAsync(
            nameof(OrchestrateDocumentProcessing),
            new PdfSummaryInput(programId, blobUri.ToString()));

        logger.LogInformation("Orchestration started with ID {InstanceId}", instanceId);
    }

    // ── Orchestrator ──────────────────────────────────────────────────────────
    [Function(nameof(OrchestrateDocumentProcessing))]
    public static async Task OrchestrateDocumentProcessing(
        [OrchestrationTrigger] TaskOrchestrationContext context)
    {
        var input = context.GetInput<PdfSummaryInput>()!;
        var logger = context.CreateReplaySafeLogger(nameof(OrchestrateDocumentProcessing));

        logger.LogInformation("Orchestrating PDF summarization for program {ProgramId}", input.ProgramId);

        string extractedText = await context.CallActivityAsync<string>(
            nameof(AnalyzePdfActivity), input.BlobUrl);

        string summary = await context.CallActivityAsync<string>(
            nameof(SummarizeTextActivity), extractedText);

        await context.CallActivityAsync(
            nameof(CallbackApiActivity), new PdfSummaryInput(input.ProgramId, summary));
    }

    // ── Activity 1: Document Intelligence ─────────────────────────────────────
    [Function(nameof(AnalyzePdfActivity))]
    public async Task<string> AnalyzePdfActivity(
        [ActivityTrigger] string blobUrl,
        FunctionContext context)
    {
        var logger = context.GetLogger(nameof(AnalyzePdfActivity));
        var endpoint = new Uri(Environment.GetEnvironmentVariable("DOCUMENT_INTELLIGENCE_ENDPOINT")!);
        var credential = new DefaultAzureCredential();
        var client = new DocumentAnalysisClient(endpoint, credential);

        logger.LogInformation("Analyzing PDF at {BlobUrl}", blobUrl);
        AnalyzeDocumentOperation operation = await client.AnalyzeDocumentFromUriAsync(
            WaitUntil.Completed, "prebuilt-read", new Uri(blobUrl));

        AnalyzeResult result = operation.Value;
        return string.Join("\n", result.Pages
            .SelectMany(p => p.Lines)
            .Select(l => l.Content));
    }

    // ── Activity 2: Azure OpenAI Summarization ────────────────────────────────
    [Function(nameof(SummarizeTextActivity))]
    public async Task<string> SummarizeTextActivity(
        [ActivityTrigger] string extractedText,
        FunctionContext context)
    {
        var logger = context.GetLogger(nameof(SummarizeTextActivity));
        var endpoint = new Uri(Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT")!);
        var deployment = Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT")!;
        var credential = new DefaultAzureCredential();
        var client = new AzureOpenAIClient(endpoint, credential);
        var chatClient = client.GetChatClient(deployment);

        logger.LogInformation("Summarizing extracted text ({Length} chars)", extractedText.Length);

        truncatedText = extractedText.Length > 60_000
            ? extractedText[..60_000] + "\n[Content truncated for summarization]"
            : extractedText;

        ChatCompletion completion = await chatClient.CompleteChatAsync(
        [
            new SystemChatMessage(
                "You are a government document summarizer. Write a concise plain-language summary " +
                "in 3–5 sentences. Focus on the program's purpose, eligibility, and key benefits. " +
                "Do not reproduce personally identifiable information."),
            new UserChatMessage($"Summarize this Ontario government program document:\n\n{truncatedText}")
        ]);

        return completion.Content[0].Text;
    }

    // ── Activity 3: Callback to Spring Boot API ────────────────────────────────
    [Function(nameof(CallbackApiActivity))]
    public async Task CallbackApiActivity(
        [ActivityTrigger] PdfSummaryInput input,
        FunctionContext context,
        [FromServices] IHttpClientFactory httpClientFactory)
    {
        var logger = context.GetLogger(nameof(CallbackApiActivity));
        var apiBaseUrl = Environment.GetEnvironmentVariable("API_BASE_URL")!;
        var httpClient = httpClientFactory.CreateClient();

        // Use Managed Identity token for the API app
        var credential = new DefaultAzureCredential();
        var tokenRequest = new Azure.Core.TokenRequestContext(
            [$"api://{Environment.GetEnvironmentVariable("API_CLIENT_ID")}/.default"]);
        var token = await credential.GetTokenAsync(tokenRequest);
        httpClient.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Token);

        var url = $"{apiBaseUrl}/api/programs/{input.ProgramId}/summary";
        logger.LogInformation("Posting summary to {Url}", url);

        var response = await httpClient.PatchAsJsonAsync(url, new SummaryCallbackPayload(input.BlobUrl));
        response.EnsureSuccessStatusCode();
    }
}
```

Note: `input.BlobUrl` is reused to carry the `summary` text in `CallbackApiActivity` (input record second field). Consider a separate record for clarity in production code.

Success criteria:
* All three activities compile and are annotated with `[Function]`
* `DefaultAzureCredential` used for all Azure service calls
* No hard-coded keys or endpoints — all from environment variables

Dependencies:
* Step 5.1 (.csproj with correct package references)

---

### Step 5.3: Create `functions/PdfSummarizer/local.settings.json`

Provide local development settings (not committed to source control via `.gitignore`).

Files:
* `functions/PdfSummarizer/local.settings.json` — new file (add to `.gitignore`)

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "DOCUMENT_INTELLIGENCE_ENDPOINT": "https://<your-docintel>.cognitiveservices.azure.com/",
    "AZURE_OPENAI_ENDPOINT": "https://<your-openai>.openai.azure.com/",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o",
    "API_BASE_URL": "http://localhost:8080",
    "API_CLIENT_ID": ""
  }
}
```

Add `functions/PdfSummarizer/local.settings.json` to `.gitignore` if not already covered.

Success criteria:
* File exists for local `func start` testing
* Not committed to source control (`.gitignore` covers it)

Dependencies:
* None

---

### Step 5.4: Create `functions/PdfSummarizer/host.json`

Provide the Functions host configuration.

Files:
* `functions/PdfSummarizer/host.json` — new file

```json
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "maxTelemetryItemsPerSecond": 20
      }
    }
  },
  "extensions": {
    "durableTask": {
      "hubName": "PdfSummarizerHub"
    }
  }
}
```

Success criteria:
* `host.json` present; `func start` does not fail with schema errors

Dependencies:
* None

---

## Implementation Phase 6: CI/CD

<!-- parallelizable: false -->

### Step 6.1: Update `.github/workflows/` — add Functions build step

Locate the existing CI/CD workflow and add a job or step to build and publish the .NET Functions project.

Files:
* `.github/workflows/*.yml` — inspect existing file(s) and add build step

Build step to add (within the CI job after the backend build):

```yaml
- name: Build Azure Functions
  run: dotnet build functions/PdfSummarizer/PdfSummarizer.csproj --configuration Release

- name: Publish Azure Functions
  run: dotnet publish functions/PdfSummarizer/PdfSummarizer.csproj \
    --configuration Release \
    --output functions/PdfSummarizer/publish
```

If a CD workflow deploys to Azure Functions App Service, add:

```yaml
- name: Deploy to Azure Function App
  uses: Azure/functions-action@v1
  with:
    app-name: ${{ vars.FUNCTION_APP_NAME }}
    package: functions/PdfSummarizer/publish
```

Success criteria:
* CI pipeline builds the Functions project without errors
* Build step runs after backend and frontend steps (or in parallel job if independent)

Dependencies:
* Step 5.1 (`.csproj` must exist)

---

## Implementation Phase 7: Validation

<!-- parallelizable: false -->

### Step 7.1: Run full project validation

Execute all validation commands for all modified components:

```bash
# Backend
cd backend && mvn verify -q

# Frontend
cd frontend && npm run lint && npm test -- --watchAll=false && npm run build

# Functions
cd functions/PdfSummarizer && dotnet build --configuration Release
```

### Step 7.2: Fix minor validation issues

Iterate on lint errors, build warnings, and test failures.
Apply fixes directly when corrections are isolated (type annotation, import, missing null check).

### Step 7.3: Report blocking issues

When validation failures require changes beyond minor fixes:
* Document the issues and affected files with specific error messages.
* Provide user with next steps (additional research or planning).
* Do not attempt large-scale refactoring within this phase.

---

## Dependencies

* .NET 8 SDK (CI runners and local development)
* Azure Functions Core Tools v4 (for local `func start`)
* Java 21 + Maven 3.9+ (backend build)
* Node.js 20 LTS + npm (frontend build)
* Azure subscription with Cognitive Services quota for Document Intelligence S0 and Azure OpenAI gpt-4o GlobalStandard

## Success Criteria

* Citizen form includes accessible, bilingual PDF file input with client-side validation
* Uploaded PDF stored at `program-documents/{programId}/{filename}` in Azure Blob Storage with no public access
* Azure Function blob trigger fires, generates AI summary via Document Intelligence + OpenAI, and PATCHes it back within 30–60 seconds
* Ministry Review Detail page shows AI summary in Ontario Design System callout with bilingual disclaimer
* All Azure service authentication uses Managed Identity — no credentials in config or source control
* Backend `mvn verify` passes including existing tests
* Frontend `npm test` passes including existing accessibility tests
