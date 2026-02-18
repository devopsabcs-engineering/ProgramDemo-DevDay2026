package com.ontario.demo.programdemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main entry point for the OPS Program Approval Demo application.
 *
 * <p>Spring Boot application serving REST API endpoints for citizen
 * program submissions and ministry review workflows.</p>
 */
@SpringBootApplication
public class ProgramDemoApplication {

    /**
     * Starts the Spring Boot application.
     *
     * @param args command-line arguments
     */
    public static void main(String[] args) {
        SpringApplication.run(ProgramDemoApplication.class, args);
    }
}
