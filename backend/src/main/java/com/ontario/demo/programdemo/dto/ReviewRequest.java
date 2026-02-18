package com.ontario.demo.programdemo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for reviewing (approving or rejecting) a program submission.
 *
 * <p>Used by ministry employees when making a decision on a
 * citizen's program request through the internal portal.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewRequest {

    /** Decision status: must be APPROVED or REJECTED. */
    @NotNull(message = "Status is required")
    private String status;

    /** Comments from the reviewer explaining the decision. */
    @NotBlank(message = "Review comments are required")
    private String reviewComments;

    /** Ministry employee performing the review. */
    @NotBlank(message = "Reviewed by is required")
    @Size(max = 100, message = "Reviewed by must not exceed 100 characters")
    private String reviewedBy;
}
