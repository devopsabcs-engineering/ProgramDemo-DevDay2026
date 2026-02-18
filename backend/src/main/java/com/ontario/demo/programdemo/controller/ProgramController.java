package com.ontario.demo.programdemo.controller;

import com.ontario.demo.programdemo.dto.ProgramRequest;
import com.ontario.demo.programdemo.dto.ProgramResponse;
import com.ontario.demo.programdemo.dto.ReviewRequest;
import com.ontario.demo.programdemo.service.ProgramService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

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

    private final ProgramService programService;

    /**
     * Constructs the controller with the required service dependency.
     *
     * @param programService the program business logic service
     */
    public ProgramController(ProgramService programService) {
        this.programService = programService;
    }

    /**
     * Submits a new program request from a citizen.
     *
     * @param request the validated program submission data
     * @return the created program with HTTP 201 status
     */
    @PostMapping
    public ResponseEntity<ProgramResponse> createProgram(
            @Valid @RequestBody ProgramRequest request) {
        ProgramResponse response = programService.createProgram(request);
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
}
