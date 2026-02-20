# PDF Summarizer Repo Research

**Repository:** `devopsabcs-engineering/Intelligent-PDF-Summarizer-Dotnet`
**Research Date:** 2026-02-20
**Researcher:** GitHub Copilot (subagent)

---

## Overview

The repository is a .NET 10 Azure Durable Functions application that ingests PDFs
from Azure Blob Storage, extracts text via Azure Document Intelligence (Form Recognizer),
and summarizes it via Azure OpenAI using a `TextCompletionInput` attribute binding.
It is deployed with the Azure Developer CLI (`azd up`).

---

## Architecture

```
PDF Upload → Blob Storage (input/)
                    ↓  BlobTrigger
              DurableFunctionApp
                    ↓  Orchestrator: ProcessDocument
         ┌──────────────────────────────┐
         │ 1. AnalyzePdf                │  Azure Document Intelligence (Form Recognizer)
         │    prebuilt-layout model     │  → extracts text page-by-page
         │ 2. WriteExtractedText        │  → saves to Blob Storage (extracted/)
         │ 3. SummarizeText             │  Azure OpenAI TextCompletionInput binding
         │    CHAT_MODEL_DEPLOYMENT_NAME│  → produces Markdown summary (max 4096 tokens)
         │ 4. WriteDoc                  │  → saves summary .md to Blob Storage (output/)
         └──────────────────────────────┘
```

---

## 1. PDF Ingestion / Upload

**Method:** Direct upload to Azure Blob Storage `input` container.

- No HTTP upload endpoint — the caller (user or app) places a PDF file in the `input`
  Blob Storage container directly (via Azure Storage Explorer, AzCopy, SDK, portal, etc.).
- A `BlobTrigger` attribute on the `BlobTrigger` function fires automatically on upload.

**Trigger code (PdfSummarizer.cs):**

```csharp
[Function("BlobTrigger")]
public async Task BlobTrigger(
    [BlobTrigger("input/{name}", Connection = "AzureWebJobsStorage")] Stream myBlob,
    string name,
    [DurableClient] DurableTaskClient starter,
    FunctionContext context)
{
    await starter.ScheduleNewOrchestrationInstanceAsync("ProcessDocument", name);
}
```

- Connection string key: `AzureWebJobsStorage`
- Container name: `input`
- Blob URI env var: `AzureWebJobsStorage__blobServiceUri`

---

## 2. Text Extraction from PDF

**Service:** Azure Cognitive Services / Document Intelligence (Form Recognizer)

- Activity function `AnalyzePdf` downloads the blob from the `input` container using
  `BlobServiceClient` and `BlobClient.DownloadContentAsync()`.
- Sends the stream to `DocumentAnalysisClient.AnalyzeDocumentAsync()` with the
  `prebuilt-layout` model.
- Iterates pages and lines, building a plain-text string with page markers
  (`--- Page N ---`).
- Returns the full extracted string to the orchestrator.

**Relevant env vars:**

| Variable | Purpose |
|---|---|
| `COGNITIVE_SERVICES_ENDPOINT` | `https://<name>.cognitiveservices.azure.com/` |

**Authentication:** `DefaultAzureCredential` (managed identity / developer credentials).

---

## 3. AI Summarization — Azure OpenAI

**Method:** `[TextCompletionInput]` binding attribute from the
`Microsoft.Azure.Functions.Worker.Extensions.OpenAI` NuGet package (v0.18.0-alpha).

No explicit `HttpClient` or OpenAI SDK call is made in the application code.
The binding infrastructure handles the call to Azure OpenAI automatically via the
attribute parameters.

**Summarization function (PdfSummarizer.cs):**

```csharp
[Function("SummarizeText")]
public async Task<string> SummarizeText(
    [ActivityTrigger] string results,
    [TextCompletionInput(
        "Provide a comprehensive and detailed summary of the following text in Markdown format. "
        + "Use headings, subheadings, and bullet points to organize the content. "
        + "Cover all major topics, key arguments, conclusions, and important details. "
        + "Be thorough and do not omit significant content.\n\nText:\n{results}",
        Model = "%CHAT_MODEL_DEPLOYMENT_NAME%",
        MaxTokens = "4096")]
    TextCompletionResponse response,
    FunctionContext context)
{
    return response.Content.ToString();
}
```

**Key points:**

- The extracted text (`{results}`) is injected into the prompt via binding interpolation.
- `Model` uses the `CHAT_MODEL_DEPLOYMENT_NAME` app setting (referenced using `%...%` syntax).
- `MaxTokens = "4096"` controls summary length and cost.
- Output type: `TextCompletionResponse` — the `.Content` property holds the Markdown string.
- The summary is saved as `{blobName-without-extension}-summary.md` in the `output` container.

**Relevant env vars:**

| Variable | Purpose |
|---|---|
| `AZURE_OPENAI_ENDPOINT` | `https://<name>.openai.azure.com/` |
| `CHAT_MODEL_DEPLOYMENT_NAME` | Azure OpenAI deployment name (e.g., `gpt-4o`) |

---

## 4. Key Files

| File | Role |
|---|---|
| `PdfSummarizer.cs` | Main application logic — all Azure Functions (trigger, orchestrator, activities) in one `DurableFunctionApp` class |
| `Program.cs` | Azure Functions isolated worker host bootstrap (minimal) |
| `pdf-summarizer-dotnet.csproj` | .NET 10 project; NuGet package definitions |
| `local.settings.json` | Local dev env vars (not committed; template in README) |
| `host.json` | Azure Functions host configuration |
| `infra/` | Azure Bicep IaC for all provisioned resources |
| `azure.yaml` | AZD project definition |
| `input/`, `extracted/`, `output/` | Sample blob containers tracked in repo |

---

## 5. Key NuGet Packages

| Package | Version | Purpose |
|---|---|---|
| `Microsoft.Azure.Functions.Worker.Extensions.DurableTask` | 1.14.1 | Durable Functions orchestration |
| `Microsoft.Azure.Functions.Worker.Extensions.OpenAI` | 0.18.0-alpha | `[TextCompletionInput]` binding for Azure OpenAI |
| `Azure.AI.FormRecognizer` | 4.1.0 | Document Intelligence (PDF text extraction) |
| `Azure.Storage.Blobs` | 12.27.0 | Blob Storage read/write |
| `Azure.Identity` | 1.17.1 | `DefaultAzureCredential` authentication |
| `Microsoft.Azure.Functions.Worker.Extensions.Storage.Blobs` | 6.8.0 | `[BlobTrigger]` binding |

---

## 6. Configuration Summary (`local.settings.json`)

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsFeatureFlags": "EnableWorkerIndexing",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AzureWebJobsStorage": "UseDevelopment=true",
    "COGNITIVE_SERVICES_ENDPOINT": "https://<name>.cognitiveservices.azure.com/",
    "AZURE_OPENAI_ENDPOINT": "https://<name>.openai.azure.com/",
    "CHAT_MODEL_DEPLOYMENT_NAME": "<deployment-name>"
  }
}
```

---

## 7. Orchestration Flow (Durable Functions)

```
ProcessDocument (orchestrator)
  ├── AnalyzePdf          (activity) → string (extracted text)
  ├── WriteExtractedText  (activity) → writes to extracted/ container
  ├── SummarizeText       (activity) → string (Markdown summary via Azure OpenAI)
  └── WriteDoc            (activity) → writes summary .md to output/ container
```

- Retry policy: 3 attempts, 5s initial interval (applied to all activities).
- Each activity result is passed as input to the next (pipeline pattern).
- Durable Functions guarantee order and durability — no queues or state stores needed.

---

## 8. Sources

| Source | URL |
|---|---|
| Repository main page | <https://github.com/devopsabcs-engineering/Intelligent-PDF-Summarizer-Dotnet> |
| README | <https://raw.githubusercontent.com/devopsabcs-engineering/Intelligent-PDF-Summarizer-Dotnet/main/README.md> |
| PdfSummarizer.cs (raw) | <https://raw.githubusercontent.com/devopsabcs-engineering/Intelligent-PDF-Summarizer-Dotnet/main/PdfSummarizer.cs> |
| Program.cs (raw) | <https://raw.githubusercontent.com/devopsabcs-engineering/Intelligent-PDF-Summarizer-Dotnet/main/Program.cs> |
| pdf-summarizer-dotnet.csproj (raw) | <https://raw.githubusercontent.com/devopsabcs-engineering/Intelligent-PDF-Summarizer-Dotnet/main/pdf-summarizer-dotnet.csproj> |
