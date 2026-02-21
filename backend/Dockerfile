# ─── Stage 1: Build ───
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn clean package -DskipTests -q

# ─── Stage 2: Runtime ───
FROM eclipse-temurin:21-jre-jammy
LABEL maintainer="OPS Program Demo <devday2026@ontario.ca>"

# Create non-root user
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --no-create-home appuser

WORKDIR /app

# Copy the built JAR
COPY --from=build /app/target/program-demo-*.jar app.jar

# Download Application Insights Java agent for auto-instrumentation.
# The agent reads APPLICATIONINSIGHTS_CONNECTION_STRING from the environment
# and auto-instruments HTTP, SQL, dependencies, logs, and exceptions.
ADD https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.6.2/applicationinsights-agent-3.6.2.jar applicationinsights-agent.jar

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=120s \
  CMD curl -f http://localhost:8080/api/programs || exit 1

# Run as non-root
USER appuser

# JVM tuning for containers — attach the Application Insights Java agent
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom -javaagent:/app/applicationinsights-agent.jar"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dserver.port=8080 -jar app.jar"]
