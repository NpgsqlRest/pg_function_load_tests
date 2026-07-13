FROM maven:3.9.16-eclipse-temurin-25-alpine AS builder

WORKDIR /app
COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:25-jre-alpine

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

# Enable virtual threads
CMD ["java", "-Dspring.threads.virtual.enabled=true", "-jar", "app.jar"]
