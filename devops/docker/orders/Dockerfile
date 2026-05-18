FROM maven:3.9-eclipse-temurin-21-alpine AS build

WORKDIR /build

COPY src/orders/pom.xml ./
RUN mvn dependency:go-offline

COPY src/orders/src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

LABEL org.opencontainers.image.title="retail-store-orders" \
      org.opencontainers.image.description="Orders service - Spring Boot/Java" \
      org.opencontainers.image.source="https://github.com/abdulmanan-ali/retail-store-devops-platform"

COPY --from=build /build/target/orders-0.0.1-SNAPSHOT.jar /app.jar

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]