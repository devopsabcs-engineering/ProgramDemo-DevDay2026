package com.ontario.demo.programdemo.service;

import com.ontario.demo.programdemo.dto.ProgramRequest;
import com.ontario.demo.programdemo.dto.ProgramResponse;
import com.ontario.demo.programdemo.dto.ReviewRequest;
import com.ontario.demo.programdemo.model.Program;
import com.ontario.demo.programdemo.model.ProgramStatus;
import com.ontario.demo.programdemo.model.ProgramType;
import com.ontario.demo.programdemo.repository.ProgramRepository;
import com.ontario.demo.programdemo.repository.ProgramTypeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Service layer for program submission business logic.
 *
 * <p>Handles creating, retrieving, searching, and reviewing
 * program submissions with proper validation and mapping
 * between entities and DTOs.</p>
 */
@Service
public class ProgramService {

    private final ProgramRepository programRepository;
    private final ProgramTypeRepository programTypeRepository;

    /**
     * Constructs the service with required repository dependencies.
     *
     * @param programRepository     repository for program entities
     * @param programTypeRepository repository for program type entities
     */
    public ProgramService(ProgramRepository programRepository,
                          ProgramTypeRepository programTypeRepository) {
        this.programRepository = programRepository;
        this.programTypeRepository = programTypeRepository;
    }

    /**
     * Creates a new program submission from a citizen request.
     *
     * @param request the program submission data
     * @return the created program as a response DTO
     * @throws IllegalArgumentException if the program type ID is invalid
     */
    @Transactional
    public ProgramResponse createProgram(ProgramRequest request) {
        ProgramType programType = programTypeRepository.findById(request.getProgramTypeId())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Program type not found with ID: " + request.getProgramTypeId()));

        Program program = new Program();
        program.setProgramName(request.getProgramName());
        program.setProgramDescription(request.getProgramDescription());
        program.setProgramType(programType);
        program.setStatus(ProgramStatus.SUBMITTED);
        program.setSubmittedBy(request.getSubmittedBy());
        program.setDocumentUrl(request.getDocumentUrl());
        program.setBudget(request.getBudget());

        Program saved = programRepository.save(program);
        return toResponse(saved);
    }

    /**
     * Retrieves all programs, optionally filtered by a search term.
     *
     * @param search optional search term to filter by program name
     * @return list of matching programs as response DTOs
     */
    @Transactional(readOnly = true)
    public List<ProgramResponse> getPrograms(String search) {
        List<Program> programs;
        if (search != null && !search.isBlank()) {
            programs = programRepository.findByProgramNameContainingIgnoreCase(search);
        } else {
            programs = programRepository.findAll();
        }
        return programs.stream().map(this::toResponse).toList();
    }

    /**
     * Retrieves a single program by its ID.
     *
     * @param id the program ID
     * @return the program as a response DTO
     * @throws IllegalArgumentException if the program is not found
     */
    @Transactional(readOnly = true)
    public ProgramResponse getProgramById(Long id) {
        Program program = programRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Program not found with ID: " + id));
        return toResponse(program);
    }

    /**
     * Reviews a program submission by approving or rejecting it.
     *
     * @param id      the program ID to review
     * @param request the review decision data
     * @return the updated program as a response DTO
     * @throws IllegalArgumentException if the program is not found or the status is invalid
     */
    @Transactional
    public ProgramResponse reviewProgram(Long id, ReviewRequest request) {
        Program program = programRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Program not found with ID: " + id));

        ProgramStatus newStatus;
        try {
            newStatus = ProgramStatus.valueOf(request.getStatus().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(
                    "Invalid status: " + request.getStatus()
                            + ". Must be APPROVED or REJECTED.");
        }

        if (newStatus != ProgramStatus.APPROVED && newStatus != ProgramStatus.REJECTED) {
            throw new IllegalArgumentException(
                    "Review status must be APPROVED or REJECTED, got: " + newStatus);
        }

        program.setStatus(newStatus);
        program.setReviewedBy(request.getReviewedBy());
        program.setReviewComments(request.getReviewComments());

        Program updated = programRepository.save(program);
        return toResponse(updated);
    }

    /**
     * Maps a Program entity to a ProgramResponse DTO.
     *
     * @param program the entity to map
     * @return the response DTO
     */
    private ProgramResponse toResponse(Program program) {
        return ProgramResponse.builder()
                .id(program.getId())
                .programName(program.getProgramName())
                .programDescription(program.getProgramDescription())
                .programTypeId(program.getProgramType().getId())
                .programTypeNameEn(program.getProgramType().getTypeNameEn())
                .programTypeNameFr(program.getProgramType().getTypeNameFr())
                .status(program.getStatus())
                .submittedBy(program.getSubmittedBy())
                .reviewedBy(program.getReviewedBy())
                .reviewComments(program.getReviewComments())
                .documentUrl(program.getDocumentUrl())
                .aiSummary(program.getAiSummary())
                .budget(program.getBudget())
                .createdDate(program.getCreatedDate())
                .updatedDate(program.getUpdatedDate())
                .build();
    }

    /**
     * Updates the document URL for a program after a successful blob upload.
     *
     * @param id          the program ID
     * @param documentUrl the full blob URL of the uploaded document
     * @throws IllegalArgumentException if the program is not found
     */
    @Transactional
    public void updateDocumentUrl(Long id, String documentUrl) {
        Program program = programRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Program not found with ID: " + id));
        program.setDocumentUrl(documentUrl);
        programRepository.save(program);
    }

    /**
     * Persists an AI-generated summary for a program submission.
     * Called via PATCH callback from the Azure Function App after document analysis.
     *
     * @param id      the program ID
     * @param summary the AI-generated plain-language summary
     * @throws IllegalArgumentException if the program is not found
     */
    @Transactional
    public void updateAiSummary(Long id, String summary) {
        Program program = programRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Program not found with ID: " + id));
        program.setAiSummary(summary);
        program.setAiSummaryGeneratedDate(java.time.LocalDateTime.now());
        programRepository.save(program);
    }
}
