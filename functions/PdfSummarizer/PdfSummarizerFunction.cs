using Azure;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.DurableTask.Client;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using OpenAI.Chat;
using System.Net.Http.Json;

namespace PdfSummarizer;

/// <summary>Input record for the orchestration and activity chain.</summary>
/// <param name="ProgramId">The program ID from the blob path prefix.</param>
/// <param name="BlobUrl">Blob URL (reused to carry the summary text in the final activity).</param>
public record PdfSummaryInput(string ProgramId, string BlobUrl);

/// <summary>Payload posted to the Spring Boot PATCH /summary endpoint.</summary>
/// <param name="Summary">The AI-generated plain-language summary.</param>
public record SummaryCallbackPayload(string Summary);

/// <summary>
/// Durable Functions pipeline that extracts text from a PDF blob, generates an AI
/// summary, and POSTs it back to the Spring Boot API via a PATCH callback.
/// </summary>
public class PdfSummarizerFunction
{
    // ── Blob Trigger ──────────────────────────────────────────────────────────
    /// <summary>
    /// Fires when a new blob is uploaded to the <c>program-documents</c> container.
    /// Starts a Durable orchestration instance.
    /// </summary>
    [Function(nameof(TriggerProcessDocument))]
    public async Task TriggerProcessDocument(
        [BlobTrigger("program-documents/{programId}/{name}",
            Connection = "AzureWebJobsStorage")] Stream pdfStream,
        string programId,
        string name,
        [DurableClient] DurableTaskClient starter,
        FunctionContext context)
    {
        var logger = context.GetLogger(nameof(TriggerProcessDocument));
        logger.LogInformation(
            "Blob trigger fired for program {ProgramId}, blob {Name}", programId, name);

        // Construct the blob URL from the storage endpoint and blob path.
        var storageEndpoint = Environment.GetEnvironmentVariable("AzureWebJobsStorage__accountName");
        var blobUrl = storageEndpoint != null
            ? $"https://{storageEndpoint}.blob.core.windows.net/program-documents/{programId}/{name}"
            : $"program-documents/{programId}/{name}";

        string instanceId = await starter.ScheduleNewOrchestrationInstanceAsync(
            nameof(OrchestrateDocumentProcessing),
            new PdfSummaryInput(programId, blobUrl));

        logger.LogInformation("Orchestration started with ID {InstanceId}", instanceId);
    }

    // ── Orchestrator ──────────────────────────────────────────────────────────
    /// <summary>
    /// Orchestrates the three-activity pipeline: extract → summarize → callback.
    /// </summary>
    [Function(nameof(OrchestrateDocumentProcessing))]
    public static async Task OrchestrateDocumentProcessing(
        [OrchestrationTrigger] TaskOrchestrationContext context)
    {
        var input = context.GetInput<PdfSummaryInput>()!;
        var logger = context.CreateReplaySafeLogger(nameof(OrchestrateDocumentProcessing));

        logger.LogInformation(
            "Orchestrating PDF summarization for program {ProgramId}", input.ProgramId);

        string extractedText = await context.CallActivityAsync<string>(
            nameof(AnalyzePdfActivity), input.BlobUrl);

        string summary = await context.CallActivityAsync<string>(
            nameof(SummarizeTextActivity), extractedText);

        await context.CallActivityAsync(
            nameof(CallbackApiActivity), new PdfSummaryInput(input.ProgramId, summary));
    }

    // ── Activity 1: Document Intelligence ────────────────────────────────────
    /// <summary>
    /// Extracts plain text from the PDF using Azure AI Document Intelligence.
    /// Uses <c>DefaultAzureCredential</c> — Managed Identity in Azure, developer credentials locally.
    /// </summary>
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
    /// <summary>
    /// Generates a concise plain-language summary using Azure OpenAI gpt-4o.
    /// Uses <c>DefaultAzureCredential</c> — no API keys.
    /// </summary>
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

        // Truncate to avoid token limit exceeding gpt-4o context window
        var truncatedText = extractedText.Length > 60_000
            ? extractedText[..60_000] + "\n[Content truncated for summarization]"
            : extractedText;

        logger.LogInformation(
            "Summarizing extracted text ({Length} chars)", truncatedText.Length);

        ChatCompletion completion = await chatClient.CompleteChatAsync(
        [
            new SystemChatMessage(
                "You are a government document summarizer. Write a concise plain-language summary " +
                "in 3\u20135 sentences. Focus on the program\u2019s purpose, eligibility, and key benefits. " +
                "Do not reproduce personally identifiable information."),
            new UserChatMessage(
                $"Summarize this Ontario government program document:\n\n{truncatedText}")
        ]);

        return completion.Content[0].Text;
    }

    // ── Activity 3: Callback to Spring Boot API ───────────────────────────────
    /// <summary>
    /// PATCHes the generated summary back to the Spring Boot API using an HTTP callback.
    /// </summary>
    [Function(nameof(CallbackApiActivity))]
    public async Task CallbackApiActivity(
        [ActivityTrigger] PdfSummaryInput input,
        FunctionContext context)
    {
        var logger = context.GetLogger(nameof(CallbackApiActivity));
        var apiBaseUrl = Environment.GetEnvironmentVariable("API_BASE_URL")!;

        var httpClientFactory = context.InstanceServices.GetRequiredService<IHttpClientFactory>();
        var httpClient = httpClientFactory.CreateClient();

        var url = $"{apiBaseUrl}/api/programs/{input.ProgramId}/summary";
        logger.LogInformation("Posting summary to {Url}", url);

        // input.BlobUrl carries the summary text in the callback activity
        var response = await httpClient.PatchAsJsonAsync(
            url,
            new SummaryCallbackPayload(input.BlobUrl));

        response.EnsureSuccessStatusCode();
        logger.LogInformation(
            "Successfully persisted AI summary for program {ProgramId}", input.ProgramId);
    }
}
