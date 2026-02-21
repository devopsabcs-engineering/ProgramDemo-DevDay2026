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
# Use curl -fSL to follow redirects and fail on HTTP errors (unlike ADD
# which silently saves a 404 HTML page as the JAR). Validate the file is
# a real ZIP/JAR by checking the magic bytes (PK header = 50 4b).
RUN curl -fSL --retry 3 -o applicationinsights-agent.jar \
      "https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.5.4/applicationinsights-agent-3.5.4.jar" && \
    head -c2 applicationinsights-agent.jar | od -An -tx1 | grep -q '50 4b' && \
    echo "Application Insights agent downloaded and validated successfully" || \
    (echo "WARNING: Agent download failed or file is not a valid JAR — removing" && rm -f applicationinsights-agent.jar)

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=120s \
  CMD curl -f http://localhost:8080/api/programs || exit 1

# Run as non-root
USER appuser

# JVM tuning for containers. The agent is loaded conditionally — if the JAR
# is missing or invalid the app still starts without instrumentation.
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

ENTRYPOINT ["sh", "-c", "AGENT_OPT=''; if [ -s /app/applicationinsights-agent.jar ]; then AGENT_OPT='-javaagent:/app/applicationinsights-agent.jar'; fi; java $JAVA_OPTS $AGENT_OPT -Dserver.port=8080 -jar app.jar"]
