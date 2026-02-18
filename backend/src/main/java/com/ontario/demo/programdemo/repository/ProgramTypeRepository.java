package com.ontario.demo.programdemo.repository;

import com.ontario.demo.programdemo.model.ProgramType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Spring Data JPA repository for {@link ProgramType} entities.
 *
 * <p>Provides CRUD operations for the program type lookup table
 * containing bilingual category names.</p>
 */
@Repository
public interface ProgramTypeRepository extends JpaRepository<ProgramType, Integer> {
}
