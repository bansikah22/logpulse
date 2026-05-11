#!/bin/bash

# LogPulse Deployment Script
# This script deploys the complete LogPulse stack to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "================================================================"
echo "                    LogPulse Deployment                         "
echo "           The Log Lifecycle Observability Stack                "
echo "================================================================"
echo -e "${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: docker is not installed. Please install docker first.${NC}"
    exit 1
fi

# Check if connected to a Kubernetes cluster
echo -e "${YELLOW}Checking Kubernetes cluster connection...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Not connected to a Kubernetes cluster. Please check your kubeconfig.${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Connected to Kubernetes cluster${NC}"

# Build the Docker image for the noisy-service
echo -e "${YELLOW}Building noisy-service Docker image...${NC}"
cd app
docker build -t logpulse/noisy-service:latest .
cd ..
echo -e "${GREEN}[OK] Docker image built successfully${NC}"

# Check if using minikube and load image
if command -v minikube &> /dev/null && kubectl config current-context | grep -q "minikube"; then
    echo -e "${YELLOW}Loading image into minikube...${NC}"
    minikube image load logpulse/noisy-service:latest
    echo -e "${GREEN}[OK] Image loaded into minikube${NC}"
fi

# Check if using kind and load image
if command -v kind &> /dev/null && kubectl config current-context | grep -q "kind"; then
    echo -e "${YELLOW}Loading image into kind cluster...${NC}"
    kind load docker-image logpulse/noisy-service:latest
    echo -e "${GREEN}[OK] Image loaded into kind${NC}"
fi

# Create namespace
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml
echo -e "${GREEN}[OK] Namespace created${NC}"

# Deploy components in order
echo -e "${YELLOW}Deploying LogPulse components...${NC}"

# 1. Deploy Loki (Storage Layer)
echo -e "${BLUE}Deploying Loki (Storage Layer)...${NC}"
kubectl apply -f k8s/loki/configmap.yaml
kubectl apply -f k8s/loki/pvc.yaml
kubectl apply -f k8s/loki/statefulset.yaml
kubectl apply -f k8s/loki/service.yaml
echo -e "${GREEN}[OK] Loki deployed${NC}"

# Wait for Loki to be ready
echo -e "${YELLOW}Waiting for Loki to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=loki -n logpulse --timeout=120s
echo -e "${GREEN}[OK] Loki is ready${NC}"

# 2. Deploy Promtail (Collection Layer)
echo -e "${BLUE}Deploying Promtail (Collection Layer)...${NC}"
kubectl apply -f k8s/promtail/rbac.yaml
kubectl apply -f k8s/promtail/configmap.yaml
kubectl apply -f k8s/promtail/daemonset.yaml
echo -e "${GREEN}[OK] Promtail deployed${NC}"

# 3. Deploy Grafana (Visualization Layer)
echo -e "${BLUE}Deploying Grafana (Visualization Layer)...${NC}"
kubectl apply -f k8s/grafana/configmap.yaml
kubectl apply -f k8s/grafana/datasources.yaml
kubectl apply -f k8s/grafana/dashboards-configmap.yaml
kubectl apply -f k8s/grafana/deployment.yaml
kubectl apply -f k8s/grafana/service.yaml
echo -e "${GREEN}[OK] Grafana deployed${NC}"

# Wait for Grafana to be ready
echo -e "${YELLOW}Waiting for Grafana to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n logpulse --timeout=120s
echo -e "${GREEN}[OK] Grafana is ready${NC}"

# 4. Deploy the noisy-service (Generation Layer)
echo -e "${BLUE}Deploying Noisy Service (Generation Layer)...${NC}"
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml
echo -e "${GREEN}[OK] Noisy Service deployed${NC}"

# Wait for noisy-service to be ready
echo -e "${YELLOW}Waiting for Noisy Service to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=noisy-service -n logpulse --timeout=120s
echo -e "${GREEN}[OK] Noisy Service is ready${NC}"

# Print status
echo -e "${BLUE}"
echo "================================================================"
echo "                    Deployment Complete!                        "
echo "================================================================"
echo -e "${NC}"

echo -e "${GREEN}All components deployed successfully!${NC}"
echo ""
echo -e "${YELLOW}Pod Status:${NC}"
kubectl get pods -n logpulse

echo ""
echo -e "${YELLOW}Services:${NC}"
kubectl get services -n logpulse

echo ""
echo -e "${YELLOW}Access the stack:${NC}"
echo -e "  Grafana UI:    ${GREEN}http://localhost:30030${NC} (NodePort)"
echo -e "  Grafana Port-forward: ${GREEN}kubectl port-forward -n logpulse svc/grafana 3000:3000${NC}"
echo ""
echo -e "${YELLOW}Default Credentials:${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}admin${NC}"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "  View logs:     ${GREEN}kubectl logs -f -n logpulse -l app=noisy-service${NC}"
echo -e "  Check status:  ${GREEN}kubectl get pods -n logpulse${NC}"
echo -e "  Cleanup:       ${GREEN}./scripts/cleanup.sh${NC}"
echo ""