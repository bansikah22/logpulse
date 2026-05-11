#!/bin/bash

# LogPulse Cleanup Script
# This script removes all LogPulse components from Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${YELLOW}"
echo "================================================================"
echo "                    LogPulse Cleanup                            "
echo "             Removing all components from cluster               "
echo "================================================================"
echo -e "${NC}"

# Ask for confirmation
read -p "Are you sure you want to remove all LogPulse components? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Removing LogPulse components...${NC}"

# Delete in reverse order of deployment

# 1. Delete Noisy Service
echo -e "${BLUE}Removing Noisy Service...${NC}"
kubectl delete -f k8s/app/deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/app/service.yaml --ignore-not-found=true
echo -e "${GREEN}[OK] Noisy Service removed${NC}"

# 2. Delete Grafana
echo -e "${BLUE}Removing Grafana...${NC}"
kubectl delete -f k8s/grafana/service.yaml --ignore-not-found=true
kubectl delete -f k8s/grafana/deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/grafana/dashboards-configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/grafana/datasources.yaml --ignore-not-found=true
kubectl delete -f k8s/grafana/configmap.yaml --ignore-not-found=true
echo -e "${GREEN}[OK] Grafana removed${NC}"

# 3. Delete Promtail
echo -e "${BLUE}Removing Promtail...${NC}"
kubectl delete -f k8s/promtail/daemonset.yaml --ignore-not-found=true
kubectl delete -f k8s/promtail/configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/promtail/rbac.yaml --ignore-not-found=true
echo -e "${GREEN}[OK] Promtail removed${NC}"

# 4. Delete Loki
echo -e "${BLUE}Removing Loki...${NC}"
kubectl delete -f k8s/loki/service.yaml --ignore-not-found=true
kubectl delete -f k8s/loki/statefulset.yaml --ignore-not-found=true
kubectl delete -f k8s/loki/pvc.yaml --ignore-not-found=true
kubectl delete -f k8s/loki/configmap.yaml --ignore-not-found=true
echo -e "${GREEN}[OK] Loki removed${NC}"

# 5. Delete Namespace
echo -e "${BLUE}Removing namespace...${NC}"
kubectl delete -f k8s/namespace.yaml --ignore-not-found=true
echo -e "${GREEN}[OK] Namespace removed${NC}"

# Optional: Remove Docker image
read -p "Do you want to remove the Docker image as well? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing Docker image...${NC}"
    docker rmi logpulse/noisy-service:latest 2>/dev/null || true
    echo -e "${GREEN}[OK] Docker image removed${NC}"
fi

echo -e "${GREEN}"
echo "================================================================"
echo "                    Cleanup Complete!                           "
echo "================================================================"
echo -e "${NC}"

echo -e "${YELLOW}All LogPulse components have been removed from the cluster.${NC}"