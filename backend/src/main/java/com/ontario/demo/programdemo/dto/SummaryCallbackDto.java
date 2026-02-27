package com.ontario.demo.programdemo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request body for the PATCH {@code /api/programs/{id}/summary} callback endpoint.
 *
 * <p>The Azure Function App calls this endpoint after generating an AI summary
 * from the uploaded PDF document.</p>
 */
public class SummaryCallbackDto {

    /** The AI-generated plain-language summary of the submitted document. */
    @NotBlank(message = "Summary must not be blank")
    @Size(max = 10000, message = "Summary must not exceed 10000 characters")
    private String summary;

    /**
     * Returns the AI-generated summary text.
     *
     * @return the summary
     */
    public String getSummary() {
        return summary;
    }

    /**
     * Sets the AI-generated summary text.
     *
     * @param summary the summary to set
     */
    public void setSummary(String summary) {
        this.summary = summary;
    }
}
