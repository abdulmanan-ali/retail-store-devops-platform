FROM maven:3.9-eclipse-temurin-21-alpine AS build

WORKDIR /build

COPY src/cart/pom.xml ./
RUN mvn dependency:go-offline

COPY src/cart/src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

LABEL org.opencontainers.image.title="retail-store-cart" \
      org.opencontainers.image.description="Cart service - Spring Boot/Java" \
      org.opencontainers.image.source="https://github.com/abdulmanan-ali/retail-store-devops-platform"

COPY --from=build /build/target/carts-0.0.1-SNAPSHOT.jar /app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app.jar"]

    