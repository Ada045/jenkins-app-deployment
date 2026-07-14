# Use an official, minimal JRE image for production runtime (keeps image small)
FROM eclipse-temurin:17-jre-jammy

# Create a non-root user and app directory (improves security)
RUN groupadd -r app && useradd -r -g app app && mkdir /app && chown app:app /app

WORKDIR /app
USER app

# Copy only the built artifact. This leverages layer caching in CI:
# if the JAR doesn't change, this layer is cached and rebuilds are fast.
# Expect CI (Jenkins) to build the application and place the artifact at target/*.jar
COPY --chown=app:app target/*.jar /app/app.jar

# Expose the application port; changed from 8080 to avoid Jenkins collision
# Change this if your app needs a different port
EXPOSE 8081

# Default JVM options (override at runtime or in CI with environment variables)
ENV JAVA_TOOL_OPTIONS="-Xms256m -Xmx512m"

# Run the pre-built JAR. Use the exec form (no shell) so signals are handled
# correctly and the container can be cleanly stopped by orchestration platforms.
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
