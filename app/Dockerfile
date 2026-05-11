# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download || true

# Copy source code
COPY main.go .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o noisy-service .

# Runtime stage
FROM alpine:3.19

WORKDIR /app

# Install ca-certificates for HTTPS connections
RUN apk --no-cache add ca-certificates

# Copy binary from builder
COPY --from=builder /app/noisy-service .

# Create non-root user for security
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser

USER appuser

# Expose no ports (log generator only)
# Environment variables:
# APP_NAME - Name of the application (default: noisy-service)
# ENVIRONMENT - Environment name (default: development)
# TEAM - Team name (default: platform)
# LOG_INTERVAL_MS - Interval between logs in milliseconds (default: 500)
# NOISE_LEVEL - Error rate from 0.0 to 1.0 (default: 0.1)

ENTRYPOINT ["./noisy-service"]