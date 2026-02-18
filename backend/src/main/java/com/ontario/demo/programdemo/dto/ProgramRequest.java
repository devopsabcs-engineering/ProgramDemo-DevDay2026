package com.ontario.demo.programdemo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for creating a new program submission.
 *
 * <p>Contains validated fields required from the citizen when
 * submitting a new program request through the public portal.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProgramRequest {

    /** Name of the program. */
    @NotBlank(message = "Program name is required")
    @Size(max = 200, message = "Program name must not exceed 200 characters")
    private String programName;

    /** Detailed description of the program request. */
    @NotBlank(message = "Program description is required")
    private String programDescription;

    /** ID of the program type from the lookup table. */
    @NotNull(message = "Program type is required")
    private Integer programTypeId;

    /** Email or user ID of the citizen submitting the request. */
    @Size(max = 100, message = "Submitted by must not exceed 100 characters")
    private String submittedBy;

    /** URL to a supporting document. */
    @Size(max = 500, message = "Document URL must not exceed 500 characters")
    private String documentUrl;
}
