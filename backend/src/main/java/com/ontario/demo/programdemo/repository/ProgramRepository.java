package com.ontario.demo.programdemo.repository;

import com.ontario.demo.programdemo.model.Program;
import com.ontario.demo.programdemo.model.ProgramStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Spring Data JPA repository for {@link Program} entities.
 *
 * <p>Provides CRUD operations and custom query methods for
 * program submissions using method-name-based queries.</p>
 */
@Repository
public interface ProgramRepository extends JpaRepository<Program, Long> {

    /**
     * Finds programs whose name contains the given search term (case-insensitive).
     *
     * @param programName the search term to match against program names
     * @return list of matching programs
     */
    List<Program> findByProgramNameContainingIgnoreCase(String programName);

    /**
     * Finds all programs with the given status.
     *
     * @param status the program status to filter by
     * @return list of programs with the specified status
     */
    List<Program> findByStatus(ProgramStatus status);

    /**
     * Finds all programs submitted by a specific citizen.
     *
     * @param submittedBy the citizen email or user ID
     * @return list of programs submitted by the citizen
     */
    List<Program> findBySubmittedBy(String submittedBy);
}
