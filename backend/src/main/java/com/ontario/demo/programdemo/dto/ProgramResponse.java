package com.ontario.demo.programdemo.dto;

import com.ontario.demo.programdemo.model.ProgramStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for returning program submission details.
 *
 * <p>Separates the API response representation from the JPA entity
 * to control which fields are exposed to API consumers.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProgramResponse {

    /** Unique identifier. */
    private Long id;

    /** Name of the program. */
    private String programName;

    /** Detailed description of the program request. */
    private String programDescription;

    /** ID of the associated program type. */
    private Integer programTypeId;

    /** English name of the program type. */
    private String programTypeNameEn;

    /** French name of the program type. */
    private String programTypeNameFr;

    /** Current status of the program submission. */
    private ProgramStatus status;

    /** Citizen who submitted the request. */
    private String submittedBy;

    /** Ministry employee who reviewed the submission. */
    private String reviewedBy;

    /** Review comments from the ministry employee. */
    private String reviewComments;

    /** URL to the supporting document. */
    private String documentUrl;

    /** Requested budget for the program in Canadian dollars. */
    private java.math.BigDecimal budget;

    /** Record creation timestamp. */
    private LocalDateTime createdDate;

    /** Last modification timestamp. */
    private LocalDateTime updatedDate;
}
