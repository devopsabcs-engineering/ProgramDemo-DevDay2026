package com.ontario.demo.programdemo.model;

/**
 * Enumeration of possible program submission statuses.
 *
 * <p>Tracks the lifecycle of a program request from initial draft
 * through submission, review, and final decision.</p>
 */
public enum ProgramStatus {

    /** Initial state when a program request is created but not yet submitted. */
    DRAFT,

    /** Program request has been submitted by the citizen. */
    SUBMITTED,

    /** Program request is currently being reviewed by a ministry employee. */
    UNDER_REVIEW,

    /** Program request has been approved by a ministry employee. */
    APPROVED,

    /** Program request has been rejected by a ministry employee. */
    REJECTED
}
