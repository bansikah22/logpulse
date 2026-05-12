# Noisy Service

## Overview

The noisy-service is a Go application that simulates a real microservice by generating structured JSON logs at configurable intervals. It serves as the log generation layer in the LogPulse stack.

## Purpose

- Generate realistic log patterns for testing the observability stack
- Demonstrate structured logging best practices
- Provide configurable log volume and error rates
- Simulate distributed tracing with trace IDs

## Architecture

```mermaid
graph LR
    subgraph NoisyService["Noisy Service"]
        A[Log Generator] --> B[JSON Formatter]
        B --> C[Stdout Output]
    end
    
    C --> D[Container Runtime]
    D --> E[/var/log/containers]
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| APP_NAME | noisy-service | Application identifier used in logs |
| ENVIRONMENT | development | Environment name (development, staging, production) |
| TEAM | platform | Team name for log labeling |
| LOG_INTERVAL_MS | 500 | Milliseconds between log entries |
| NOISE_LEVEL | 0.15 | Error rate as decimal (0.0-1.0) |

### Example Configuration

```yaml
env:
  - name: APP_NAME
    value: "noisy-service"
  - name: ENVIRONMENT
    value: "development"
  - name: TEAM
    value: "platform"
  - name: LOG_INTERVAL_MS
    value: "500"
  - name: NOISE_LEVEL
    value: "0.15"
```

## Log Output

### Log Structure

Each log entry is a JSON object with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| timestamp | string | ISO 8601 timestamp with nanoseconds |
| level | string | Log level: INFO, WARN, ERROR |
| message | string | Log message content |
| app | string | Application name |
| environment | string | Environment name |
| team | string | Team name |
| instance | string | Pod/instance identifier |
| trace_id | string | Distributed tracing trace ID |
| span_id | string | Distributed tracing span ID |
| duration_ms | number | Simulated response time in milliseconds |
| status_code | number | Simulated HTTP status code |
| method | string | Simulated HTTP method |
| path | string | Simulated API path |
| user_id | string | Simulated user identifier |
| error | string | Error message (only for ERROR level) |
| extra | object | Additional context (only for ERROR level) |

### Sample Log Output

```json
{
  "timestamp": "2024-01-15T10:30:00.123456789Z",
  "level": "ERROR",
  "message": "Database connection timeout",
  "app": "noisy-service",
  "environment": "development",
  "team": "platform",
  "instance": "noisy-service-abc123",
  "trace_id": "a1b2c3d4e5f6789012345678901234",
  "span_id": "1234567890abcdef",
  "duration_ms": 450,
  "status_code": 500,
  "method": "POST",
  "path": "/api/users",
  "user_id": "user_1234",
  "error": "operation failed",
  "extra": {
    "retry_count": 3,
    "service": "user-service"
  }
}
```

## Log Levels

### INFO (Default - 75-85%)

Informational logs about normal operations:

- Request processed successfully
- User session created
- Cache hit/miss
- Health check passed
- Configuration reloaded
- Background job completed

### WARN (15%)

Warning logs about potential issues:

- Rate limit approaching threshold
- Slow query detected
- Cache miss
- Connection pool running low
- Memory usage high
- Deprecated API endpoint called

### ERROR (Configurable - 10-15%)

Error logs about failures:

- Database connection timeout
- Authentication failed
- External API returned 503
- Memory allocation failed
- Rate limit exceeded
- SSL certificate verification failed

## Deployment

### Kubernetes Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: noisy-service
  namespace: logpulse
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: noisy-service
  template:
    spec:
      containers:
        - name: noisy-service
          image: logpulse/noisy-service:latest
          env:
            - name: NOISE_LEVEL
              value: "0.15"
          resources:
            requests:
              cpu: 10m
              memory: 32Mi
            limits:
              cpu: 100m
              memory: 64Mi
```

### Scaling

To increase log volume, scale the deployment:

```bash
kubectl scale deployment noisy-service -n logpulse --replicas=5
```

To increase log frequency, adjust LOG_INTERVAL_MS:

```bash
kubectl set env deployment/noisy-service -n logpulse LOG_INTERVAL_MS=200
```

## Building

### Local Build

```bash
cd app
go build -o noisy-service .
```

### Docker Build

```bash
docker build -t logpulse/noisy-service:latest ./app
```

### Multi-stage Build

The Dockerfile uses a multi-stage build for minimal image size:

1. Build stage: Compiles Go binary
2. Runtime stage: Alpine-based minimal image

Final image size: ~15MB

## Testing

### Verify Logs

```bash
# View logs from all replicas
kubectl logs -f -n logpulse -l app.kubernetes.io/name=noisy-service

# View logs from specific pod
kubectl logs -f -n logpulse noisy-service-abc123

# Count logs by level
kubectl logs -n logpulse -l app.kubernetes.io/name=noisy-service | \
  jq -r '.level' | sort | uniq -c
```

### Verify JSON Format

```bash
kubectl logs -n logpulse -l app.kubernetes.io/name=noisy-service | \
  head -1 | jq .
```

## Code Structure

```
app/
├── main.go          # Application entry point
├── go.mod           # Go module definition
├── go.sum           # Dependency checksums
└── Dockerfile       # Container build instructions
```

### Key Functions

| Function | Description |
|----------|-------------|
| main() | Entry point, starts log generation loop |
| generateLog() | Creates a single log entry |
| outputLog() | Writes JSON to stdout |
| getEnv() | Reads environment variables |
| generateTraceID() | Creates random trace ID |
| generateSpanID() | Creates random span ID |
| randomChoice() | Selects random element from slice |
| randomInt() | Generates random integer in range |

## Best Practices

1. Use structured logging (JSON format)
2. Include consistent labels across all logs
3. Add trace IDs for distributed tracing
4. Keep log messages meaningful
5. Use appropriate log levels
6. Include relevant context fields
7. Avoid sensitive data in logs