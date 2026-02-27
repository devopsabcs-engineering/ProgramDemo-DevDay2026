package com.ontario.demo.programdemo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ontario.demo.programdemo.dto.ProgramRequest;
import com.ontario.demo.programdemo.dto.ProgramResponse;
import com.ontario.demo.programdemo.dto.ReviewRequest;
import com.ontario.demo.programdemo.model.ProgramStatus;
import com.ontario.demo.programdemo.service.BlobStorageService;
import com.ontario.demo.programdemo.service.ProgramService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Unit tests for {@link ProgramController} using the web layer slice.
 *
 * <p>Covers all four REST endpoints with happy paths and validation
 * error scenarios. The {@link ProgramService} is mocked to isolate
 * the controller under test.</p>
 */
@WebMvcTest(ProgramController.class)
@DisplayName("ProgramController")
class ProgramControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ProgramService programService;

    @MockBean
    private BlobStorageService blobStorageService;

    // -------------------------------------------------------------------------
    // Test data helpers
    // -------------------------------------------------------------------------

    private ProgramResponse sampleResponse(Long id, ProgramStatus status) {
        return ProgramResponse.builder()
                .id(id)
                .programName("Test Program")
                .programDescription("A test program description")
                .programTypeId(1)
                .programTypeNameEn("Health")
                .programTypeNameFr("Santé")
                .status(status)
                .submittedBy("citizen@example.com")
                .budget(new java.math.BigDecimal("250000.00"))
                .createdDate(LocalDateTime.now())
                .updatedDate(LocalDateTime.now())
                .build();
    }

    private ProgramRequest validRequest() {
        return ProgramRequest.builder()
                .programName("Test Program")
                .programDescription("A test program description")
                .programTypeId(1)
                .submittedBy("citizen@example.com")
                .build();
    }

    // -------------------------------------------------------------------------
    // POST /api/programs
    // -------------------------------------------------------------------------

    /** Creates a {@link MockMultipartFile} wrapping a JSON-serialised program request. */
    private MockMultipartFile programPart(ProgramRequest request) throws Exception {
        return new MockMultipartFile(
                "program", "", MediaType.APPLICATION_JSON_VALUE,
                objectMapper.writeValueAsBytes(request));
    }

    @Test
    @DisplayName("POST /api/programs — valid request returns 201 Created")
    void createProgram_validRequest_returns201() throws Exception {
        ProgramResponse response = sampleResponse(1L, ProgramStatus.SUBMITTED);
        when(programService.createProgram(any(ProgramRequest.class))).thenReturn(response);

        mockMvc.perform(multipart("/api/programs").file(programPart(validRequest())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1L))
                .andExpect(jsonPath("$.programName").value("Test Program"))
                .andExpect(jsonPath("$.status").value("SUBMITTED"));
    }

    @Test
    @DisplayName("POST /api/programs — missing programName returns 400")
    void createProgram_missingProgramName_returns400() throws Exception {
        ProgramRequest request = ProgramRequest.builder()
                .programDescription("A description")
                .programTypeId(1)
                .build();

        mockMvc.perform(multipart("/api/programs").file(programPart(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.programName").exists());
    }

    @Test
    @DisplayName("POST /api/programs — missing programDescription returns 400")
    void createProgram_missingDescription_returns400() throws Exception {
        ProgramRequest request = ProgramRequest.builder()
                .programName("Test Program")
                .programTypeId(1)
                .build();

        mockMvc.perform(multipart("/api/programs").file(programPart(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.programDescription").exists());
    }

    @Test
    @DisplayName("POST /api/programs — missing programTypeId returns 400")
    void createProgram_missingProgramTypeId_returns400() throws Exception {
        ProgramRequest request = ProgramRequest.builder()
                .programName("Test Program")
                .programDescription("A description")
                .build();

        mockMvc.perform(multipart("/api/programs").file(programPart(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.programTypeId").exists());
    }

    // -------------------------------------------------------------------------
    // GET /api/programs
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("GET /api/programs — no filter returns all programs")
    void getPrograms_noFilter_returnsAll() throws Exception {
        List<ProgramResponse> programs = List.of(
                sampleResponse(1L, ProgramStatus.SUBMITTED),
                sampleResponse(2L, ProgramStatus.APPROVED));
        when(programService.getPrograms(null)).thenReturn(programs);

        mockMvc.perform(get("/api/programs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    @DisplayName("GET /api/programs?search=test — returns filtered programs")
    void getPrograms_withSearch_returnsFiltered() throws Exception {
        List<ProgramResponse> programs = List.of(sampleResponse(1L, ProgramStatus.SUBMITTED));
        when(programService.getPrograms("test")).thenReturn(programs);

        mockMvc.perform(get("/api/programs").param("search", "test"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].programName").value("Test Program"));
    }

    // -------------------------------------------------------------------------
    // GET /api/programs/{id}
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("GET /api/programs/{id} — found returns 200")
    void getProgramById_found_returns200() throws Exception {
        ProgramResponse response = sampleResponse(1L, ProgramStatus.SUBMITTED);
        when(programService.getProgramById(1L)).thenReturn(response);

        mockMvc.perform(get("/api/programs/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1L))
                .andExpect(jsonPath("$.programTypeNameEn").value("Health"));
    }

    @Test
    @DisplayName("GET /api/programs/{id} — not found returns 400")
    void getProgramById_notFound_returns400() throws Exception {
        when(programService.getProgramById(999L))
                .thenThrow(new IllegalArgumentException("Program not found with ID: 999"));

        mockMvc.perform(get("/api/programs/999"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value("Program not found with ID: 999"));
    }

    // -------------------------------------------------------------------------
    // PUT /api/programs/{id}/review
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("PUT /api/programs/{id}/review — approve returns 200")
    void reviewProgram_approve_returns200() throws Exception {
        ReviewRequest reviewRequest = ReviewRequest.builder()
                .status("APPROVED")
                .reviewComments("Looks good.")
                .reviewedBy("ministry@ontario.ca")
                .build();
        ProgramResponse response = sampleResponse(1L, ProgramStatus.APPROVED);
        response.setReviewedBy("ministry@ontario.ca");
        response.setReviewComments("Looks good.");
        when(programService.reviewProgram(eq(1L), any(ReviewRequest.class))).thenReturn(response);

        mockMvc.perform(put("/api/programs/1/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reviewRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"))
                .andExpect(jsonPath("$.reviewedBy").value("ministry@ontario.ca"));
    }

    @Test
    @DisplayName("PUT /api/programs/{id}/review — reject returns 200")
    void reviewProgram_reject_returns200() throws Exception {
        ReviewRequest reviewRequest = ReviewRequest.builder()
                .status("REJECTED")
                .reviewComments("Does not meet criteria.")
                .reviewedBy("ministry@ontario.ca")
                .build();
        ProgramResponse response = sampleResponse(1L, ProgramStatus.REJECTED);
        response.setReviewedBy("ministry@ontario.ca");
        response.setReviewComments("Does not meet criteria.");
        when(programService.reviewProgram(eq(1L), any(ReviewRequest.class))).thenReturn(response);

        mockMvc.perform(put("/api/programs/1/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reviewRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"));
    }

    @Test
    @DisplayName("POST /api/programs — negative budget returns 400")
    void createProgram_negativeBudget_returns400() throws Exception {
        ProgramRequest request = ProgramRequest.builder()
                .programName("Test Program")
                .programDescription("A description")
                .programTypeId(1)
                .budget(new java.math.BigDecimal("-100.00"))
                .build();

        mockMvc.perform(multipart("/api/programs").file(programPart(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/programs — valid budget is returned in response")
    void createProgram_withBudget_returnsBudgetInResponse() throws Exception {
        ProgramRequest request = ProgramRequest.builder()
                .programName("Test Program")
                .programDescription("A test program description")
                .programTypeId(1)
                .submittedBy("citizen@example.com")
                .budget(new java.math.BigDecimal("250000.00"))
                .build();
        ProgramResponse response = sampleResponse(1L, ProgramStatus.SUBMITTED);
        when(programService.createProgram(any(ProgramRequest.class))).thenReturn(response);

        mockMvc.perform(multipart("/api/programs").file(programPart(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.budget").value(250000.00));
    }

    @Test
    @DisplayName("PUT /api/programs/{id}/review — missing reviewComments returns 400")
    void reviewProgram_missingComments_returns400() throws Exception {
        ReviewRequest reviewRequest = ReviewRequest.builder()
                .status("APPROVED")
                .reviewedBy("ministry@ontario.ca")
                .build();

        mockMvc.perform(put("/api/programs/1/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reviewRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.reviewComments").exists());
    }

    @Test
    @DisplayName("PUT /api/programs/{id}/review — missing reviewedBy returns 400")
    void reviewProgram_missingReviewedBy_returns400() throws Exception {
        ReviewRequest reviewRequest = ReviewRequest.builder()
                .status("APPROVED")
                .reviewComments("Approved.")
                .build();

        mockMvc.perform(put("/api/programs/1/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reviewRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.reviewedBy").exists());
    }
}
