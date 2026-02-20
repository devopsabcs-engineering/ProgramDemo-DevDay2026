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

/**
 * Service for uploading program documents to Azure Blob Storage.
 *
 * <p>Uses {@code DefaultAzureCredential} for authentication — Managed Identity in Azure,
 * developer CLI credentials locally. No connection strings or keys are used.</p>
 */
@Service
public class BlobStorageService {

    private static final String CONTAINER_NAME = "program-documents";

    private final BlobServiceClient client;

    /**
     * Constructs the service and initialises the Blob Storage client.
     *
     * @param blobServiceUri the blob service endpoint URI (injected from configuration)
     */
    public BlobStorageService(
            @Value("${azure.storage.blob-service-uri}") String blobServiceUri) {
        this.client = new BlobServiceClientBuilder()
                .endpoint(blobServiceUri)
                .credential(new DefaultAzureCredentialBuilder().build())
                .buildClient();
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
}
