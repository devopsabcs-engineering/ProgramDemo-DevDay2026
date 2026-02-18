package com.ontario.demo.programdemo.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;

/**
 * Global exception handler for the application.
 *
 * <p>Catches exceptions across all controllers and returns RFC 7807
 * ProblemDetail responses with appropriate HTTP status codes.</p>
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Handles validation errors from {@code @Valid} annotated request bodies.
     *
     * @param ex the validation exception containing field errors
     * @return a ProblemDetail response with field-level error details
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidationException(MethodArgumentNotValidException ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        problemDetail.setTitle("Validation Error");
        problemDetail.setType(URI.create("https://ontario.ca/errors/validation"));

        Map<String, String> fieldErrors = new HashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.put(error.getField(), error.getDefaultMessage());
        }
        problemDetail.setProperty("fieldErrors", fieldErrors);

        return problemDetail;
    }

    /**
     * Handles cases where a requested resource is not found.
     *
     * @param ex the not-found exception
     * @return a ProblemDetail response with 404 status
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public ProblemDetail handleNoResourceFoundException(NoResourceFoundException ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatus(HttpStatus.NOT_FOUND);
        problemDetail.setTitle("Resource Not Found");
        problemDetail.setDetail(ex.getMessage());
        problemDetail.setType(URI.create("https://ontario.ca/errors/not-found"));
        return problemDetail;
    }

    /**
     * Handles illegal argument exceptions (e.g., invalid status transitions).
     *
     * @param ex the illegal argument exception
     * @return a ProblemDetail response with 400 status
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public ProblemDetail handleIllegalArgumentException(IllegalArgumentException ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        problemDetail.setTitle("Bad Request");
        problemDetail.setDetail(ex.getMessage());
        problemDetail.setType(URI.create("https://ontario.ca/errors/bad-request"));
        return problemDetail;
    }

    /**
     * Catches all unhandled exceptions as a fallback.
     *
     * @param ex the unhandled exception
     * @return a ProblemDetail response with 500 status
     */
    @ExceptionHandler(Exception.class)
    public ProblemDetail handleGeneralException(Exception ex) {
        ProblemDetail problemDetail = ProblemDetail.forStatus(HttpStatus.INTERNAL_SERVER_ERROR);
        problemDetail.setTitle("Internal Server Error");
        problemDetail.setDetail("An unexpected error occurred. Please try again later.");
        problemDetail.setType(URI.create("https://ontario.ca/errors/internal"));
        return problemDetail;
    }
}
