package com.ontario.demo.programdemo.service;

import com.ontario.demo.programdemo.dto.ProgramRequest;
import com.ontario.demo.programdemo.dto.ProgramResponse;
import com.ontario.demo.programdemo.dto.ReviewRequest;
import com.ontario.demo.programdemo.model.Program;
import com.ontario.demo.programdemo.model.ProgramStatus;
import com.ontario.demo.programdemo.model.ProgramType;
import com.ontario.demo.programdemo.repository.ProgramRepository;
import com.ontario.demo.programdemo.repository.ProgramTypeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link ProgramService} using Mockito.
 *
 * <p>Covers all four service methods with happy-path scenarios
 * and expected exception cases. No Spring context is loaded;
 * all repository dependencies are mocked.</p>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("ProgramService")
class ProgramServiceTest {

    @Mock
    private ProgramRepository programRepository;

    @Mock
    private ProgramTypeRepository programTypeRepository;

    @InjectMocks
    private ProgramService programService;

    private ProgramType healthType;
    private Program submittedProgram;

    @BeforeEach
    void setUp() {
        healthType = new ProgramType(1, "Health", "Santé");

        submittedProgram = new Program();
        submittedProgram.setId(1L);
        submittedProgram.setProgramName("Test Program");
        submittedProgram.setProgramDescription("A test program description");
        submittedProgram.setProgramType(healthType);
        submittedProgram.setStatus(ProgramStatus.SUBMITTED);
        submittedProgram.setSubmittedBy("citizen@example.com");
        submittedProgram.setCreatedDate(LocalDateTime.now());
        submittedProgram.setUpdatedDate(LocalDateTime.now());
    }

    // -------------------------------------------------------------------------
    // createProgram
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("createProgram — valid request creates and returns program")
    void createProgram_validRequest_createsProgram() {
        ProgramRequest request = ProgramRequest.builder()
                .programName("Test Program")
                .programDescription("A test program description")
                .programTypeId(1)
                .submittedBy("citizen@example.com")
                .build();

        when(programTypeRepository.findById(1)).thenReturn(Optional.of(healthType));
        when(programRepository.save(any(Program.class))).thenReturn(submittedProgram);

        ProgramResponse response = programService.createProgram(request);

        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getProgramName()).isEqualTo("Test Program");
        assertThat(response.getStatus()).isEqualTo(ProgramStatus.SUBMITTED);
        assertThat(response.getProgramTypeNameEn()).isEqualTo("Health");
        assertThat(response.getProgramTypeNameFr()).isEqualTo("Santé");

        verify(programRepository).save(any(Program.class));
    }

    @Test
    @DisplayName("createProgram — invalid programTypeId throws IllegalArgumentException")
    void createProgram_invalidProgramTypeId_throwsException() {
        ProgramRequest request = ProgramRequest.builder()
                .programName("Test Program")
                .programDescription("A description")
                .programTypeId(999)
                .build();

        when(programTypeRepository.findById(999)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> programService.createProgram(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Program type not found with ID: 999");
    }

    // -------------------------------------------------------------------------
    // getPrograms
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("getPrograms — no search term returns all programs")
    void getPrograms_noSearch_returnsAll() {
        when(programRepository.findAll()).thenReturn(List.of(submittedProgram));

        List<ProgramResponse> results = programService.getPrograms(null);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getProgramName()).isEqualTo("Test Program");
        verify(programRepository).findAll();
    }

    @Test
    @DisplayName("getPrograms — blank search term returns all programs")
    void getPrograms_blankSearch_returnsAll() {
        when(programRepository.findAll()).thenReturn(List.of(submittedProgram));

        List<ProgramResponse> results = programService.getPrograms("   ");

        assertThat(results).hasSize(1);
        verify(programRepository).findAll();
    }

    @Test
    @DisplayName("getPrograms — search term delegates to name search")
    void getPrograms_withSearch_delegatesToNameSearch() {
        when(programRepository.findByProgramNameContainingIgnoreCase("health"))
                .thenReturn(List.of(submittedProgram));

        List<ProgramResponse> results = programService.getPrograms("health");

        assertThat(results).hasSize(1);
        verify(programRepository).findByProgramNameContainingIgnoreCase("health");
    }

    @Test
    @DisplayName("getPrograms — search returns empty list when no match")
    void getPrograms_noMatch_returnsEmpty() {
        when(programRepository.findByProgramNameContainingIgnoreCase(anyString()))
                .thenReturn(List.of());

        List<ProgramResponse> results = programService.getPrograms("nonexistent");

        assertThat(results).isEmpty();
    }

    // -------------------------------------------------------------------------
    // getProgramById
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("getProgramById — found returns program response")
    void getProgramById_found_returnsResponse() {
        when(programRepository.findById(1L)).thenReturn(Optional.of(submittedProgram));

        ProgramResponse response = programService.getProgramById(1L);

        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getStatus()).isEqualTo(ProgramStatus.SUBMITTED);
    }

    @Test
    @DisplayName("getProgramById — not found throws IllegalArgumentException")
    void getProgramById_notFound_throwsException() {
        when(programRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> programService.getProgramById(999L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Program not found with ID: 999");
    }

    // -------------------------------------------------------------------------
    // reviewProgram
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("reviewProgram — approve updates status to APPROVED")
    void reviewProgram_approve_updatesStatus() {
        ReviewRequest request = ReviewRequest.builder()
                .status("APPROVED")
                .reviewComments("Meets criteria.")
                .reviewedBy("ministry@ontario.ca")
                .build();

        Program approvedProgram = new Program();
        approvedProgram.setId(1L);
        approvedProgram.setProgramName("Test Program");
        approvedProgram.setProgramDescription("A test program description");
        approvedProgram.setProgramType(healthType);
        approvedProgram.setStatus(ProgramStatus.APPROVED);
        approvedProgram.setSubmittedBy("citizen@example.com");
        approvedProgram.setReviewedBy("ministry@ontario.ca");
        approvedProgram.setReviewComments("Meets criteria.");
        approvedProgram.setCreatedDate(LocalDateTime.now());
        approvedProgram.setUpdatedDate(LocalDateTime.now());

        when(programRepository.findById(1L)).thenReturn(Optional.of(submittedProgram));
        when(programRepository.save(any(Program.class))).thenReturn(approvedProgram);

        ProgramResponse response = programService.reviewProgram(1L, request);

        assertThat(response.getStatus()).isEqualTo(ProgramStatus.APPROVED);
        assertThat(response.getReviewedBy()).isEqualTo("ministry@ontario.ca");
        assertThat(response.getReviewComments()).isEqualTo("Meets criteria.");
    }

    @Test
    @DisplayName("reviewProgram — reject updates status to REJECTED")
    void reviewProgram_reject_updatesStatus() {
        ReviewRequest request = ReviewRequest.builder()
                .status("REJECTED")
                .reviewComments("Does not meet the requirements.")
                .reviewedBy("ministry@ontario.ca")
                .build();

        Program rejectedProgram = new Program();
        rejectedProgram.setId(1L);
        rejectedProgram.setProgramName("Test Program");
        rejectedProgram.setProgramDescription("A test program description");
        rejectedProgram.setProgramType(healthType);
        rejectedProgram.setStatus(ProgramStatus.REJECTED);
        rejectedProgram.setSubmittedBy("citizen@example.com");
        rejectedProgram.setReviewedBy("ministry@ontario.ca");
        rejectedProgram.setReviewComments("Does not meet the requirements.");
        rejectedProgram.setCreatedDate(LocalDateTime.now());
        rejectedProgram.setUpdatedDate(LocalDateTime.now());

        when(programRepository.findById(1L)).thenReturn(Optional.of(submittedProgram));
        when(programRepository.save(any(Program.class))).thenReturn(rejectedProgram);

        ProgramResponse response = programService.reviewProgram(1L, request);

        assertThat(response.getStatus()).isEqualTo(ProgramStatus.REJECTED);
    }

    @Test
    @DisplayName("reviewProgram — invalid status throws IllegalArgumentException")
    void reviewProgram_invalidStatus_throwsException() {
        ReviewRequest request = ReviewRequest.builder()
                .status("DRAFT")
                .reviewComments("Approved.")
                .reviewedBy("ministry@ontario.ca")
                .build();

        when(programRepository.findById(1L)).thenReturn(Optional.of(submittedProgram));

        assertThatThrownBy(() -> programService.reviewProgram(1L, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Review status must be APPROVED or REJECTED");
    }

    @Test
    @DisplayName("reviewProgram — unknown status string throws IllegalArgumentException")
    void reviewProgram_unknownStatusString_throwsException() {
        ReviewRequest request = ReviewRequest.builder()
                .status("INVALID_STATUS")
                .reviewComments("Something.")
                .reviewedBy("ministry@ontario.ca")
                .build();

        when(programRepository.findById(1L)).thenReturn(Optional.of(submittedProgram));

        assertThatThrownBy(() -> programService.reviewProgram(1L, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Invalid status");
    }

    @Test
    @DisplayName("reviewProgram — program not found throws IllegalArgumentException")
    void reviewProgram_notFound_throwsException() {
        ReviewRequest request = ReviewRequest.builder()
                .status("APPROVED")
                .reviewComments("Approved.")
                .reviewedBy("ministry@ontario.ca")
                .build();

        when(programRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> programService.reviewProgram(999L, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Program not found with ID: 999");
    }
}
