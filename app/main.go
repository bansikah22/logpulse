package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"os"
	"time"
)

type LogEntry struct {
	Timestamp   string                 `json:"timestamp"`
	Level       string                 `json:"level"`
	Message     string                 `json:"message"`
	App         string                 `json:"app"`
	Environment string                 `json:"environment"`
	Team        string                 `json:"team"`
	Instance    string                 `json:"instance"`
	TraceID     string                 `json:"trace_id,omitempty"`
	SpanID      string                 `json:"span_id,omitempty"`
	Duration    int64                  `json:"duration_ms,omitempty"`
	StatusCode  int                    `json:"status_code,omitempty"`
	Method      string                 `json:"method,omitempty"`
	Path        string                 `json:"path,omitempty"`
	UserID      string                 `json:"user_id,omitempty"`
	Error       string                 `json:"error,omitempty"`
	Extra       map[string]interface{} `json:"extra,omitempty"`
}

type Config struct {
	AppName     string
	Environment string
	Team        string
	Instance    string
	LogInterval time.Duration
	NoiseLevel  float64
}

var (
	infoMessages = []string{
		"Request processed successfully",
		"User session created",
		"Cache hit for key: user_%d",
		"Database connection established",
		"Health check passed",
		"Configuration reloaded",
		"New user registered: user_%d",
		"Payment processed for order_%d",
		"Email sent to user_%d",
		"File uploaded: document_%d.pdf",
		"API response time: %dms",
		"Background job completed",
		"Websocket connection established",
		"Rate limit check passed",
		"Authentication successful for user_%d",
	}

	warnMessages = []string{
		"Rate limit approaching threshold",
		"Slow query detected: %dms",
		"Cache miss for key: user_%d",
		"Connection pool running low",
		"Memory usage at %d%%",
		"Deprecated API endpoint called: /api/v%d/%s",
		"Retry attempt %d for operation",
		"Session expiring soon for user_%d",
		"Unusual traffic pattern detected",
		"Certificate expiring in %d days",
	}

	errorMessages = []string{
		"Database connection timeout",
		"Failed to process payment for order_%d",
		"Authentication failed for user_%d",
		"External API returned 503: Service Unavailable",
		"Memory allocation failed",
		"File not found: /data/file_%d.dat",
		"Invalid request payload",
		"Rate limit exceeded for client_%d",
		"SSL certificate verification failed",
		"Redis connection refused",
		"Queue processing failed: queue_%s",
		"HTTP 500: Internal server error",
		"Database deadlock detected",
		"Network timeout after %dms",
		"Permission denied for resource",
	}

	httpMethods = []string{"GET", "POST", "PUT", "DELETE", "PATCH"}
	paths       = []string{"/api/users", "/api/orders", "/api/products", "/api/payments", "/api/auth", "/api/health", "/api/metrics"}
	services    = []string{"user-service", "order-service", "payment-service", "notification-service", "inventory-service"}
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

func main() {
	config := Config{
		AppName:     getEnv("APP_NAME", "noisy-service"),
		Environment: getEnv("ENVIRONMENT", "development"),
		Team:        getEnv("TEAM", "platform"),
		Instance:    getEnv("HOSTNAME", "instance-1"),
		LogInterval: time.Duration(getEnvInt("LOG_INTERVAL_MS", 500)) * time.Millisecond,
		NoiseLevel:  getEnvFloat("NOISE_LEVEL", 0.1),
	}

	log.Printf("Starting %s in %s environment (noise level: %.2f)", config.AppName, config.Environment, config.NoiseLevel)

	ticker := time.NewTicker(config.LogInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			generateLog(config)
		}
	}
}

func generateLog(config Config) {
	entry := LogEntry{
		Timestamp:   time.Now().UTC().Format(time.RFC3339Nano),
		App:         config.AppName,
		Environment: config.Environment,
		Team:        config.Team,
		Instance:    config.Instance,
		TraceID:     generateTraceID(),
		SpanID:      generateSpanID(),
	}

	r := rand.Float64()
	switch {
	case r < config.NoiseLevel:
		entry.Level = "ERROR"
		entry.Message = randomChoice(errorMessages)
		entry.StatusCode = randomInt(500, 599)
		entry.Error = "operation failed"
	case r < config.NoiseLevel+0.15:
		entry.Level = "WARN"
		entry.Message = randomChoice(warnMessages)
		entry.StatusCode = randomInt(400, 499)
	default:
		entry.Level = "INFO"
		entry.Message = randomChoice(infoMessages)
		entry.StatusCode = randomInt(200, 299)
	}

	entry.Method = randomChoice(httpMethods)
	entry.Path = randomChoice(paths)
	entry.Duration = int64(randomInt(1, 500))
	entry.UserID = generateUserID()

	if entry.Level == "ERROR" {
		entry.Extra = map[string]interface{}{
			"retry_count": randomInt(1, 5),
			"service":    randomChoice(services),
		}
	}

	outputLog(entry)
}

func outputLog(entry LogEntry) {
	jsonData, err := json.Marshal(entry)
	if err != nil {
		log.Printf("Error marshaling log entry: %v", err)
		return
	}

	os.Stdout.Write(jsonData)
	os.Stdout.Write([]byte("\n"))
}

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value, exists := os.LookupEnv(key); exists {
		var intValue int
		if _, err := fmt.Sscanf(value, "%d", &intValue); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvFloat(key string, defaultValue float64) float64 {
	if value, exists := os.LookupEnv(key); exists {
		var floatValue float64
		if _, err := fmt.Sscanf(value, "%f", &floatValue); err == nil {
			return floatValue
		}
	}
	return defaultValue
}

func generateTraceID() string {
	const charset = "abcdef0123456789"
	b := make([]byte, 32)
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}

func generateSpanID() string {
	const charset = "abcdef0123456789"
	b := make([]byte, 16)
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}

func generateUserID() string {
	return fmt.Sprintf("user_%d", randomInt(1000, 9999))
}

func randomChoice[T any](slice []T) T {
	return slice[rand.Intn(len(slice))]
}

func randomInt(min, max int) int {
	return rand.Intn(max-min+1) + min
}