FROM openjdk:8-jdk-alpine AS builder
WORKDIR /app

COPY pom.xml .
COPY mvnw .
COPY .mvn/ .mvn/
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline
COPY src/ src/
RUN ./mvnw package -DskipTests


FROM openjdk:8-jre-alpine
WORKDIR /app
RUN apk add --no-cache bash
COPY --from=builder /app/target/*.jar app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh
EXPOSE 8081
ENTRYPOINT ["./wait-for-it.sh", "postgres:5432", "--", "java", "-jar", "app.jar"]