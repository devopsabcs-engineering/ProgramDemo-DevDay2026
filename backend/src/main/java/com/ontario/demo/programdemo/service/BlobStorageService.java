package com.ontario.demo.programdemo.service;

import com.azure.core.util.BinaryData;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobProperties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;

/**
 * Service for uploading and downloading program documents to/from Azure Blob Storage.
 *
 * <p>Uses {@code DefaultAzureCredential} for authentication — Managed Identity in Azure,
 * developer CLI credentials locally. When the blob service URI points to
 * {@code localhost} (Azurite emulator), the well-known Azurite connection string
 * is used instead so that local development works without Azure credentials.</p>
 */
@Service
public class BlobStorageService {

    private static final String CONTAINER_NAME = "program-documents";

    /** Well-known connection string for the Azurite local storage emulator. */
    private static final String AZURITE_CONNECTION_STRING =
            "DefaultEndpointsProtocol=http;"
            + "AccountName=devstoreaccount1;"
            + "AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsu"
            + "Fq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;"
            + "BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;";

    private final BlobServiceClient client;

    /**
     * Constructs the service and initialises the Blob Storage client.
     *
     * <p>When the endpoint contains {@code localhost} or {@code 127.0.0.1}
     * (i.e. Azurite is in use), the client is built with the Azurite
     * connection string. Otherwise, {@code DefaultAzureCredential} is used.</p>
     *
     * @param blobServiceUri the blob service endpoint URI (injected from configuration)
     */
    public BlobStorageService(
            @Value("${azure.storage.blob-service-uri}") String blobServiceUri) {
        if (isLocalEmulator(blobServiceUri)) {
            this.client = new BlobServiceClientBuilder()
                    .connectionString(AZURITE_CONNECTION_STRING)
                    .buildClient();
            // Auto-create the container in Azurite (no-op if it already exists).
            this.client.getBlobContainerClient(CONTAINER_NAME).createIfNotExists();
        } else {
            this.client = new BlobServiceClientBuilder()
                    .endpoint(blobServiceUri)
                    .credential(new DefaultAzureCredentialBuilder().build())
                    .buildClient();
        }
    }

    /**
     * Returns {@code true} if the blob service URI points to a local emulator
     * (Azurite) rather than a real Azure Storage account.
     */
    private static boolean isLocalEmulator(String uri) {
        String lower = uri.toLowerCase();
        return lower.contains("localhost") || lower.contains("127.0.0.1");
    }

    /**
     * Uploads a PDF document for a program submission to the {@code program-documents} container.
     *
     * <p>Blobs are stored at path {@code {programId}/{sanitisedFilename}}.</p>
     *
     * @param programId the ID of the program (used as blob folder prefix)
     * @param file      the multipart PDF file to upload
     * @return the full blob URL of the uploaded file
     * @throws IOException if reading the file bytes fails
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

    /**
     * Downloads a document from Azure Blob Storage using managed identity.
     *
     * <p>Extracts the blob path from the full blob URL stored on the program record
     * and streams the content through the backend, avoiding direct public access
     * to the storage account (which has {@code publicNetworkAccess: Disabled}).</p>
     *
     * @param blobUrl the full blob URL (e.g. https://account.blob.core.windows.net/container/path)
     * @return the blob content as a Spring {@link Resource}
     */
    public Resource downloadDocument(String blobUrl) {
        String blobPath = extractBlobPath(blobUrl);
        BlobClient blobClient = client
                .getBlobContainerClient(CONTAINER_NAME)
                .getBlobClient(blobPath);
        InputStream stream = blobClient.openInputStream();
        return new InputStreamResource(stream);
    }

    /**
     * Retrieves the content type and content length of a blob.
     *
     * @param blobUrl the full blob URL
     * @return the blob properties
     */
    public BlobProperties getBlobProperties(String blobUrl) {
        String blobPath = extractBlobPath(blobUrl);
        BlobClient blobClient = client
                .getBlobContainerClient(CONTAINER_NAME)
                .getBlobClient(blobPath);
        return blobClient.getProperties();
    }

    /**
     * Extracts the blob path (relative to the container) from a full blob URL.
     *
     * <p>Given {@code https://account.blob.core.windows.net/program-documents/17/health_en.pdf},
     * returns {@code 17/health_en.pdf}.</p>
     *
     * @param blobUrl the full blob URL
     * @return the blob path within the container
     */
    private String extractBlobPath(String blobUrl) {
        URI uri = URI.create(blobUrl);
        String path = uri.getPath(); // e.g. /program-documents/17/health_en.pdf
        String containerPrefix = "/" + CONTAINER_NAME + "/";
        if (path.startsWith(containerPrefix)) {
            return path.substring(containerPrefix.length());
        }
        // Fallback: strip leading slash
        return path.startsWith("/") ? path.substring(1) : path;
    }
}
