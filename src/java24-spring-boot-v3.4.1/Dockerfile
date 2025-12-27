FROM maven:3.9.9-eclipse-temurin-24-alpine AS builder

WORKDIR /app
COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:24-jre-alpine

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

# Enable virtual threads
CMD ["java", "-Dspring.threads.virtual.enabled=true", "-jar", "app.jar"]
