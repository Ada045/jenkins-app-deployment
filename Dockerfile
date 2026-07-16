FROM eclipse-temurin:17-jre-jammy

RUN groupadd -r app && useradd -r -g app app && mkdir /app && chown app:app /app

WORKDIR /app
USER app

COPY --chown=app:app target/*.jar /app/app.jar

EXPOSE 8081

ENV JAVA_TOOL_OPTIONS="-Xms256m -Xmx512m"

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
