package com.ontario.demo.programdemo.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * JPA entity representing a citizen program submission.
 *
 * <p>Tracks the full lifecycle of a program request from initial
 * submission through ministry review and final decision.</p>
 */
@Entity
@Table(name = "program")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Program {

    /** Auto-increment primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Name of the program request. */
    @Column(name = "program_name", nullable = false, length = 200)
    private String programName;

    /** Detailed description of the program request. */
    @Column(name = "program_description", nullable = false, columnDefinition = "NVARCHAR(MAX)")
    private String programDescription;

    /** Reference to the program type lookup table. */
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "program_type_id", nullable = false)
    private ProgramType programType;

    /** Current status of the program submission. */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    private ProgramStatus status = ProgramStatus.DRAFT;

    /** Email or user ID of the citizen who submitted the request. */
    @Column(name = "submitted_by", length = 100)
    private String submittedBy;

    /** Ministry employee who reviewed the submission. */
    @Column(name = "reviewed_by", length = 100)
    private String reviewedBy;

    /** Comments added by the reviewer during approval or rejection. */
    @Column(name = "review_comments", columnDefinition = "NVARCHAR(MAX)")
    private String reviewComments;

    /** URL to the uploaded supporting document. */
    @Column(name = "document_url", length = 500)
    private String documentUrl;

    /** Record creation timestamp. */
    @Column(name = "created_date", nullable = false, updatable = false)
    private LocalDateTime createdDate;

    /** Last modification timestamp. */
    @Column(name = "updated_date", nullable = false)
    private LocalDateTime updatedDate;

    /**
     * Sets creation and update timestamps before initial persist.
     */
    @PrePersist
    protected void onCreate() {
        this.createdDate = LocalDateTime.now();
        this.updatedDate = LocalDateTime.now();
    }

    /**
     * Updates the modification timestamp before each update.
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedDate = LocalDateTime.now();
    }
}
