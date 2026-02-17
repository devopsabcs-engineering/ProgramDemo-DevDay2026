---
applyTo: "backend/**/*.java"
---
# Java / Spring Boot Instructions

- Use Java 21 features (records, sealed classes, pattern matching) where appropriate.
- Follow Spring Boot 3.x conventions.
- Use constructor injection, not field injection.
- Include Javadoc on all public classes and methods.
- Use Lombok @Data, @Builder, @AllArgsConstructor for DTOs.
- Handle exceptions with @ControllerAdvice and return ProblemDetail responses.
- Use Spring Data JPA repositories with method-name-based queries.
- Include @Valid on all request body parameters.
- Use ResponseEntity with appropriate HTTP status codes.
- Organize packages: config/, controller/, service/, repository/, model/, dto/.
- Unit tests use JUnit 5, Mockito, and @WebMvcTest for controllers.
- Integration tests use @SpringBootTest with an in-memory database.
