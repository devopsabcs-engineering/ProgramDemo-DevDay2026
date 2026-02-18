package com.ontario.demo.programdemo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * CORS configuration for the application.
 *
 * <p>Restricts cross-origin requests to the frontend origin only.
 * The allowed origin is configurable via the {@code app.cors.allowed-origin}
 * property, defaulting to {@code http://localhost:5173} for local development.</p>
 */
@Configuration
public class CorsConfig {

    /** The allowed frontend origin for CORS requests. */
    @Value("${app.cors.allowed-origin:http://localhost:5173}")
    private String allowedOrigin;

    /**
     * Configures CORS mappings for all API endpoints.
     *
     * @return a {@link WebMvcConfigurer} with CORS settings applied
     */
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                        .allowedOrigins(allowedOrigin)
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .allowCredentials(true)
                        .maxAge(3600);
            }
        };
    }
}
