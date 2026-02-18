package com.ontario.demo.programdemo.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * JPA entity representing a program type lookup record.
 *
 * <p>Contains bilingual (EN/FR) display names for program categories
 * such as Health, Education, and Infrastructure.</p>
 */
@Entity
@Table(name = "program_type")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProgramType {

    /** Auto-increment primary key. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /** English display name for the program type. */
    @Column(name = "type_name_en", nullable = false, length = 100)
    private String typeNameEn;

    /** French display name for the program type. */
    @Column(name = "type_name_fr", nullable = false, length = 100)
    private String typeNameFr;
}
