package com.ontario.demo.programdemo.controller;

import com.ontario.demo.programdemo.dto.ProgramRequest;
import com.ontario.demo.programdemo.dto.ProgramResponse;
import com.ontario.demo.programdemo.dto.ReviewRequest;
import com.ontario.demo.programdemo.dto.SummaryCallbackDto;
import com.ontario.demo.programdemo.service.BlobStorageService;
import com.ontario.demo.programdemo.service.ProgramService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

/**
 * REST controller for program submission and review endpoints.
 *
 * <p>Exposes CRUD operations for citizen program submissions
 * and ministry review workflows via the {@code /api/programs} base path.</p>
 */
@RestController
@RequestMapping("/api/programs")
public class ProgramController {

    private static final Logger log = LoggerFactory.getLogger(ProgramController.class);

    private final ProgramService programService;
    private final BlobStorageService blobStorageService;

    /**
     * Constructs the controller with the required service dependencies.
     *
     * @param programService     the program business logic service
     * @param blobStorageService the blob storage service for document uploads
     */
    public ProgramController(ProgramService programService,
                             BlobStorageService blobStorageService) {
        this.programService = programService;
        this.blobStorageService = blobStorageService;
    }

    /**
     * Submits a new program request from a citizen.
     *
     * <p>Accepts {@code multipart/form-data} with a required {@code program} JSON part
     * and an optional {@code document} PDF part. When a PDF is provided it is uploaded
     * to Azure Blob Storage and the resulting URL is persisted on the program record.</p>
     *
     * @param request  the validated program submission data (JSON part)
     * @param document optional PDF document to attach (multipart part, max 50 MB)
     * @return the created program with HTTP 201 status
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ProgramResponse> createProgram(
            @RequestPart("program") @Valid ProgramRequest request,
            @RequestPart(value = "document", required = false) MultipartFile document) {
        ProgramResponse response = programService.createProgram(request);
        if (document != null && !document.isEmpty()) {
            try {
                String url = blobStorageService.uploadDocument(response.getId(), document);
                programService.updateDocumentUrl(response.getId(), url);
                response = programService.getProgramById(response.getId());
            } catch (IOException e) {
                // Document upload failure is non-fatal — the program record is already saved.
                log.warn("Failed to upload document for program {}: {}", response.getId(), e.getMessage());
            }
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Lists all programs, optionally filtered by a search term.
     *
     * @param search optional query parameter to filter by program name
     * @return list of matching programs with HTTP 200 status
     */
    @GetMapping
    public ResponseEntity<List<ProgramResponse>> getPrograms(
            @RequestParam(required = false) String search) {
        List<ProgramResponse> programs = programService.getPrograms(search);
        return ResponseEntity.ok(programs);
    }

    /**
     * Retrieves a single program by its ID.
     *
     * @param id the program ID
     * @return the program details with HTTP 200 status
     */
    @GetMapping("/{id}")
    public ResponseEntity<ProgramResponse> getProgramById(@PathVariable Long id) {
        ProgramResponse response = programService.getProgramById(id);
        return ResponseEntity.ok(response);
    }

    /**
     * Reviews a program submission by approving or rejecting it.
     *
     * @param id      the program ID to review
     * @param request the validated review decision data
     * @return the updated program with HTTP 200 status
     */
    @PutMapping("/{id}/review")
    public ResponseEntity<ProgramResponse> reviewProgram(
            @PathVariable Long id,
            @Valid @RequestBody ReviewRequest request) {
        ProgramResponse response = programService.reviewProgram(id, request);
        return ResponseEntity.ok(response);
    }

    /**
     * Receives an AI-generated summary callback from the Azure Function App.
     *
     * <p>Called by the {@code PdfSummarizer} Function after Document Intelligence
     * extracts text and Azure OpenAI generates a plain-language summary.
     * Returns HTTP 204 on success.</p>
     *
     * @param id  the program ID
     * @param dto the callback payload containing the generated summary
     * @return HTTP 204 No Content on success
     */
    @PatchMapping("/{id}/summary")
    public ResponseEntity<Void> updateAiSummary(
            @PathVariable Long id,
            @Valid @RequestBody SummaryCallbackDto dto) {
        programService.updateAiSummary(id, dto.getSummary());
        return ResponseEntity.noContent().build();
    }
}

