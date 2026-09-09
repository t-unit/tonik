FROM maven:3.9.16-eclipse-temurin-26 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn --batch-mode dependency:go-offline
COPY src ./src
RUN mvn --batch-mode package
FROM eclipse-temurin:26.0.2_10-jre-noble
WORKDIR /app
COPY --from=build /app/target/catalog-1.0.0.jar app.jar
EXPOSE 8000
CMD ["java", "-jar", "app.jar"]
