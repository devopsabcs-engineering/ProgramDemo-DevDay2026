# Codebase Analysis — 2026-02-20

**Purpose:** Understand the current submission flow and available infrastructure before adding file-upload capability.

---

## 1. Backend — File Upload Handling

**Current state: No file upload support exists.**

The backend accepts only a plain `documentUrl` string field — no `MultipartFile`, no multipart endpoint, no Azure Blob Storage integration.

### Controller — [`backend/src/main/java/com/ontario/demo/programdemo/controller/ProgramController.java`](../../../backend/src/main/java/com/ontario/demo/programdemo/controller/ProgramController.java)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/programs` | Create program — accepts JSON body, returns 201 |
| `GET` | `/api/programs` | List programs, optional `?search=` filter |
| `GET` | `/api/programs/{id}` | Get single program by ID |
| `PUT` | `/api/programs/{id}/review` | Approve / reject a program submission |

The `createProgram` method (line 48) uses `@RequestBody ProgramRequest` — pure JSON, `Content-Type: application/json`. There is no `@PostMapping(consumes = MULTIPART_FORM_DATA_VALUE)` or `MultipartFile` parameter anywhere in the codebase.

### Service — [`backend/src/main/java/com/ontario/demo/programdemo/service/ProgramService.java`](../../../backend/src/main/java/com/ontario/demo/programdemo/service/ProgramService.java)

- `createProgram()` (line 48): maps `ProgramRequest` → `Program` entity, sets `status = SUBMITTED`, persists to Azure SQL.
- `documentUrl` is copied verbatim from the request to the entity (line 58): `program.setDocumentUrl(request.getDocumentUrl())`.
- No upload or cloud storage call.

---

## 2. Frontend — Form Submission

### [`frontend/src/pages/SubmitProgram.tsx`](../../../frontend/src/pages/SubmitProgram.tsx)

The citizen form collects:

| Field | Input type | Required |
|-------|-----------|----------|
| `programName` | `text` (max 200) | Yes |
| `programDescription` | `textarea` | Yes |
| `programTypeId` | `select` (IDs 1–5) | Yes |
| `submittedBy` | `email` | No |
| `documentUrl` | `url` | No |
| `budget` | `number` (min 0, step 0.01) | No |

**Key observation (line 37–43 of `SubmitProgram.tsx`):** `documentUrl` is a plain `<input type="url">` text box. There is **no `<input type="file">` element** anywhere in the form. Citizens must manually type or paste a URL.

On submit (line 111–118), `createProgram(formData)` is called, which posts the entire `ProgramRequest` as JSON.

### [`frontend/src/services/api.ts`](../../../frontend/src/services/api.ts)

```ts
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});
```

All requests use `application/json`. No `multipart/form-data` uploads exist.

The base URL is set from `VITE_API_URL` env var in production, or proxied via `/api` in development.

---

## 3. Data Models

### Entity — [`backend/src/main/java/com/ontario/demo/programdemo/model/Program.java`](../../../backend/src/main/java/com/ontario/demo/programdemo/model/Program.java)

```
program table (V002__create_program_table.sql):
  id                  BIGINT IDENTITY PK
  program_name        NVARCHAR(200) NOT NULL
  program_description NVARCHAR(MAX) NOT NULL
  program_type_id     INT FK → program_type
  status              NVARCHAR(50) DEFAULT 'DRAFT'  [DRAFT|SUBMITTED|UNDER_REVIEW|APPROVED|REJECTED]
  submitted_by        NVARCHAR(100) NULL
  reviewed_by         NVARCHAR(100) NULL
  review_comments     NVARCHAR(MAX) NULL
  document_url        NVARCHAR(500) NULL            ← stores a URL string only
  budget              DECIMAL(15,2) NULL            ← added in V005/V006
  created_date        DATETIME2 NOT NULL
  updated_date        DATETIME2 NOT NULL
```

### DTO [`ProgramRequest.java`](../../../backend/src/main/java/com/ontario/demo/programdemo/dto/ProgramRequest.java)

Fields: `programName` (@NotBlank, max 200), `programDescription` (@NotBlank), `programTypeId` (@NotNull), `submittedBy` (max 100), `documentUrl` (max 500), `budget` (BigDecimal, ≥ 0).

### DTO [`ProgramResponse.java`](../../../backend/src/main/java/com/ontario/demo/programdemo/dto/ProgramResponse.java)

Adds: `id`, `programTypeNameEn`, `programTypeNameFr`, `status`, `reviewedBy`, `reviewComments`, `createdDate`, `updatedDate`.

### Frontend [`frontend/src/types/index.ts`](../../../frontend/src/types/index.ts)

```ts
interface ProgramRequest {
  programName: string;
  programDescription: string;
  programTypeId: number;
  submittedBy?: string;
  documentUrl?: string;
  budget?: number | null;
}
```

---

## 4. Azure Infrastructure Already Provisioned

Source: [`infra/main.bicep`](../../../infra/main.bicep), [`infra/modules/`](../../../infra/modules/)

| Resource | Module | Notes |
|----------|--------|-------|
| **Azure Storage Account** | `modules/storage.bicep` | StorageV2, Standard_LRS, `allowBlobPublicAccess: false`, no blob containers defined |
| **Azure App Service — Backend** | `modules/web-app.bicep` (suffix `api`) | Docker container from ACR, VNet-integrated, managed identity for SQL auth |
| **Azure App Service — Frontend** | `modules/web-app.bicep` (suffix `web`) | Node 20-lts, pm2 SPA serve |
| **Azure SQL** | `modules/sql.bicep` | Private endpoint, AAD-only auth via managed identity |
| **Azure Container Registry** | `modules/container-registry.bicep` | Basic SKU, MI-based pull |
| **Azure Function App** | `modules/function-app.bicep` | Dotnet-isolated, consumption plan (Y1), uses Storage Account |
| **Azure Logic App** | `modules/logic-app.bicep` | Notifications workflow |
| **Virtual Network** | `modules/vnet.bicep` | App subnet + private endpoint subnet |
| **User-Assigned Managed Identity** | `modules/sql-admin-identity.bicep` | SQL AAD admin + ACR pull |

### Storage Account Key Details

From [`infra/modules/storage.bicep`](../../../infra/modules/storage.bicep):
- Name pattern: `st{prefix}{env}{instance}{uniqueString}` (max 24 chars)
- `allowBlobPublicAccess: false` — blobs require authenticated access
- Currently used **only** for Azure Functions runtime (`AzureWebJobsStorage`)
- **No blob containers provisioned** for user document uploads
- Network ACL `defaultAction: Allow` with `bypass: AzureServices`

---

## 5. Application Configuration

### [`backend/src/main/resources/application.yml`](../../../backend/src/main/resources/application.yml)

```yaml
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:sqlserver://localhost:1433;...}
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
  jpa:
    hibernate.ddl-auto: validate
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: ${SERVER_PORT:8080}
```

**No Azure Storage / Azure Blob configuration.**  
**No `spring.servlet.multipart` configuration** (file upload size limits, etc.).

---

## 6. Summary: Gaps for File Upload Feature

| Gap | Location | What's Missing |
|-----|----------|---------------|
| No file-picker UI | `frontend/src/pages/SubmitProgram.tsx` | `<input type="file">` + multipart submit logic |
| No upload API in `api.ts` | `frontend/src/services/api.ts` | `uploadDocument()` function using `FormData` |
| No multipart endpoint | `ProgramController.java` | `@PostMapping("/upload")` with `MultipartFile` |
| No Azure Blob SDK | `backend/pom.xml` | `azure-storage-blob` / `spring-cloud-azure-starter-storage-blob` dependency |
| No blob container in infra | `infra/modules/storage.bicep` | `blobServices` + container resource |
| No storage app settings on backend App Service | `infra/main.bicep` | `AZURE_STORAGE_ACCOUNT_NAME`, `AZURE_STORAGE_CONTAINER_NAME` env vars |
| No multipart config in application.yml | `backend/src/main/resources/application.yml` | `spring.servlet.multipart.max-file-size` etc. |

---

*Generated: 2026-02-20 | Analyst: GitHub Copilot*
