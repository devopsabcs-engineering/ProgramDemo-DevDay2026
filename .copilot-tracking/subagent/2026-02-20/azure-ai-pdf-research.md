# Azure AI PDF Summarization Research

**Date:** 2026-02-20  
**Researcher:** GitHub Copilot (Subagent)  
**Topic:** Simplest Microsoft-provided approach to summarize a PDF document

---

## Executive Summary

Four Microsoft services can participate in PDF summarization. The **simplest end-to-end path** is the **Azure OpenAI Assistants API with File Search**, which accepts a raw PDF upload, handles chunking and embedding automatically, and returns a natural-language summary — all within roughly 20 lines of Python. No intermediate text extraction step is required.

---

## Service-by-Service Analysis

### 1. Azure AI Document Intelligence (formerly Form Recognizer)

**Source:** <https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/overview>  
**Source:** <https://learn.microsoft.com/azure/ai-services/document-intelligence/prebuilt/read>

**What it does for PDFs:**

- The `prebuilt-read` model extracts printed and handwritten text from PDFs via OCR.
- Supports up to **2,000 pages** per request; file sizes up to **500 MB** (paid tier).
- Returns structured JSON containing paragraphs, lines, words, spans, bounding polygons, and page layout.
- Also produces a **searchable PDF** output (`output=pdf`) that embeds extracted text back into the original file — useful for downstream search.
- Fully text-based PDFs (not scanned images) work best; fully scanned images-only PDFs are not supported by the Language service's native summarization.

**For summarization use:**

Document Intelligence only **extracts** text. You must then pipe extracted text to a separate service (Azure OpenAI, Language Service) for actual summarization. This is a **two-step pipeline**:

```
PDF → Document Intelligence (prebuilt-read) → extracted text → Azure OpenAI chat completion → summary
```

**Verdict:** Works and is GA, but **not the simplest path** — adds a separate API call and response parsing before you can summarize.

---

### 2. Azure OpenAI Service — Assistants API with File Search

**Source:** <https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/file-search>

**What it does:**

- The **File Search** tool on the Assistants API accepts PDF uploads directly (`.pdf` is listed as a supported file type with MIME `application/pdf`).
- Azure OpenAI **automatically parses, chunks (800-token chunks, 400-token overlap), embeds (text-embedding-3-large at 256 dims), and stores** the file in a managed vector store.
- Once the vector store is attached to an assistant, you can send a single user message such as *"Summarize this document"* and GPT-4o (or any supported model) will retrieve the relevant chunks and produce a summary.
- Supports up to **10,000 files** per vector store; max **512 MB** per file; max **5,000,000 tokens** per file.
- Vector stores created via thread message attachments expire after **7 days** by default (configurable).

**Minimal Python code path (approx 20 lines):**

```python
from openai import AzureOpenAI

client = AzureOpenAI(api_key=..., api_version="2024-05-01-preview", azure_endpoint=...)

# 1. Create assistant
assistant = client.beta.assistants.create(
    name="PDF Summarizer",
    instructions="Summarize the attached document concisely.",
    model="gpt-4o",
    tools=[{"type": "file_search"}],
)

# 2. Upload PDF and create vector store in one call
vector_store = client.beta.vector_stores.create(name="My PDF")
file_batch = client.beta.vector_stores.file_batches.upload_and_poll(
    vector_store_id=vector_store.id,
    files=[open("document.pdf", "rb")]
)

# 3. Attach vector store and run
assistant = client.beta.assistants.update(
    assistant_id=assistant.id,
    tool_resources={"file_search": {"vector_store_ids": [vector_store.id]}},
)
thread = client.beta.threads.create(
    messages=[{"role": "user", "content": "Summarize this document."}]
)
run = client.beta.threads.runs.create_and_poll(thread_id=thread.id, assistant_id=assistant.id)
messages = client.beta.threads.messages.list(thread_id=thread.id)
print(messages.data[0].content[0].text.value)
```

**Caveats:**

- File Search tool incurs **additional vector storage charges** beyond per-token API fees.
- The Assistants API is still in **Preview** (as of docs last updated 2025-11-21).
- Microsoft recommends migrating toward the new **Foundry Agent Service** (GA) for enterprise use.
- Available only in [regions that support Assistants](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure).

**Verdict:** ✅ **Simplest path for ad-hoc or application-integrated PDF summarization.** One service, one upload, one prompt.

---

### 3. AI Foundry — Azure AI Content Understanding

**Source:** <https://learn.microsoft.com/en-us/azure/ai-services/content-understanding/overview>

**What it does:**

- Azure AI Content Understanding is **GA** as of API version `2025-11-01`.
- Accepts **Documents, Images, Video, and Audio** as input — PDFs are explicitly supported.
- Processes content through a pipeline: OCR extraction → segmentation → **field extraction** (via schema you define).
- The **"Generate"** field extraction method can generate summaries freely from input data (e.g., "summarize this document" as a field schema definition).
- Outputs structured **JSON** (matching your schema) or **Markdown** (for RAG/search scenarios).
- Provides **confidence scores** and **source grounding** (tracing values back to the exact location in the source PDF).
- Includes **prebuilt analyzers** for common scenarios (invoices, contracts, tax forms, call analytics, etc.).
- Requires a **Microsoft Foundry Resource** (not a standalone AI service resource).

**For summarization use:**

You would define a custom analyzer with a "Generate" field like:

```json
{
  "fields": {
    "summary": {
      "type": "string",
      "method": "generate",
      "description": "A concise summary of the document"
    }
  }
}
```

Then POST the PDF to the Analyze API — Content Understanding handles OCR and LLM generation automatically.

**Verdict:** More setup than Assistants API (requires Foundry Resource, analyzer schema definition, async job polling) but **GA**, structured, and built for production automation pipelines. Best for high-volume, schema-driven workflows.

---

### 4. Azure AI Language Service — Native Document Summarization

**Source:** <https://learn.microsoft.com/en-us/azure/ai-services/language-service/summarization/how-to/document-summarization>

**What it does:**

- Azure Language Service supports **native document summarization** for `.pdf`, `.docx`, and `.txt` without a separate text extraction step.
- Supports both:
  - **Extractive summarization** — returns top-ranked existing sentences from the document.
  - **Abstractive summarization** — generates a new concise paragraph summarizing the content.
- Limits: ≤ 20 documents per request, ≤ 10 MB total content, no fully scanned PDFs.
- **Important limitation:** Requires Azure Blob Storage — source PDF must be in a Blob Storage container (SAS URL), and the summary result is written to a target Blob Storage container. This is not a simple "send PDF, get summary" call.
- Uses an **async job pattern**: POST to submit, poll GET to get results.
- **Status:** Still in **Preview** (public preview as of docs dated 2025-11-18).

**Verdict:** Good for batch, compliance, or audit workflows where Blob Storage integration is already available, but **not the simplest** due to mandatory Blob Storage dependency and async polling.

---

## Comparison Table

| Service | PDF Support | Summarization Type | Setup Complexity | Status | Best For |
|---|---|---|---|---|---|
| **Document Intelligence (prebuilt-read)** | ✅ Native | ❌ Extraction only (text out) | Low (single API) | GA | Preprocessing before GPT summarization |
| **Azure OpenAI Assistants + File Search** | ✅ Native | ✅ GPT-quality abstractive | Very Low (~20 lines) | Preview | Simplest ad-hoc summarization |
| **Azure AI Content Understanding** | ✅ Native | ✅ GPT-powered (schema-driven) | Medium (Foundry resource + analyzer schema) | GA | Structured, production automation |
| **Language Service Native Summarization** | ✅ Native (digital only) | ✅ Extractive + Abstractive | Medium-High (requires Blob Storage) | Preview | Batch/compliance workflows |

---

## Recommendation: Simplest Path

> **Azure OpenAI Assistants API + File Search** is the simplest Microsoft path to summarize a PDF.

Steps:
1. Create an Azure OpenAI resource with a GPT-4o deployment.
2. Upload the PDF via `client.beta.vector_stores.file_batches.upload_and_poll()`.
3. Create an assistant with `file_search` tool enabled.
4. Send "Summarize this document" in a thread run.
5. Read the response.

No Document Intelligence needed. No Blob Storage needed. No custom schema needed.

**For production / high-volume automated pipelines:** Use **Azure AI Content Understanding** (GA, structured output, confidence scores, grounding).

**For large-scale batch workloads at lowest cost:** Consider Azure OpenAI **Global Batch API** at 50% cost reduction over standard, combining Document Intelligence text extraction with a batch summarization prompt.

---

## Key Caveats for Implementation

- The Assistants API File Search is **Preview** — Microsoft recommends evaluating the **Foundry Agent Service** (GA) as the successor.
- Fully scanned/image-only PDFs require Document Intelligence OCR first, before any Language Service summarization.
- All services require an appropriate Azure subscription and regional availability check.
- File Search vector storage has additional cost; set expiration policies to control spend.
- Validate that the Azure OpenAI region in use supports Assistants API before implementing.

---

## References

| Resource | URL |
|---|---|
| Document Intelligence Overview | <https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/overview> |
| Document Intelligence Read Model | <https://learn.microsoft.com/azure/ai-services/document-intelligence/prebuilt/read> |
| Azure OpenAI Assistants File Search | <https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/file-search> |
| Azure AI Content Understanding Overview | <https://learn.microsoft.com/en-us/azure/ai-services/content-understanding/overview> |
| Language Native Document Summarization | <https://learn.microsoft.com/en-us/azure/ai-services/language-service/summarization/how-to/document-summarization> |
| Language Summarization Overview | <https://learn.microsoft.com/azure/ai-services/language-service/summarization/overview> |
