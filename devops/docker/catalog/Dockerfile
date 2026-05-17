FROM golang:1.24-alpine AS build-env

WORKDIR /appsrc

COPY src/catalog/go.mod src/catalog/go.sum ./
RUN GOFLAGS="-mod=mod" GOTOOLCHAIN=auto go mod download

COPY src/catalog/ .
RUN CGO_ENABLED=0 GOOS=linux GOTOOLCHAIN=auto go build -ldflags="-w -s" -o main main.go

FROM gcr.io/distroless/static:nonroot

LABEL org.opencontainers.image.title="retail-store-catalog" \
      org.opencontainers.image.description="Catalog service - Go/MySQL" \
      org.opencontainers.image.source="https://github.com/abdulmanan-ali/retail-store-devops-platform"

COPY --from=build-env /appsrc/main /app/main

EXPOSE 8080

ENTRYPOINT ["/app/main"]