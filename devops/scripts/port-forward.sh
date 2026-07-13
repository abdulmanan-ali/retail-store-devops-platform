#!/usr/bin/env bash

set -euo pipefail

# Check if kubectl is installed
if ! command -v kubectl >/dev/null 2>&1; then
    echo "❌ Error: kubectl is not installed."
    exit 1
fi

# Check if Kubernetes cluster is reachable
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Error: Unable to connect to a Kubernetes cluster."
    echo "Make sure your cluster is running and your kubeconfig is configured."
    exit 1
fi

echo "==============================================="
echo " Starting port-forwards for Retail Store"
echo "==============================================="
echo

# Kill all background jobs when exiting
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# -----------------------------------------
# Retail Store Services
# -----------------------------------------

kubectl -n retail-store port-forward svc/ui 8080:8080 --address=0.0.0.0 &
kubectl -n retail-store port-forward svc/catalog 8081:8080 --address=0.0.0.0 &
kubectl -n retail-store port-forward svc/cart 8082:8080 --address=0.0.0.0 &
kubectl -n retail-store port-forward svc/orders 8083:8080 --address=0.0.0.0 &
kubectl -n retail-store port-forward svc/checkout 8084:8080 --address=0.0.0.0 &

# -----------------------------------------
# Monitoring
# -----------------------------------------

kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80 --address=0.0.0.0 &
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 --address=0.0.0.0 &
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 --address=0.0.0.0 &

# -----------------------------------------
# ArgoCD
# -----------------------------------------

kubectl -n argocd port-forward svc/argocd-server 8888:443 --address=0.0.0.0 &

# -----------------------------------------
# NGINX Ingress
# -----------------------------------------

kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8090:80 --address=0.0.0.0 &

# Give kubectl a moment to start
sleep 2

echo
echo "==============================================="
echo " Port-Forward Summary"
echo "==============================================="
printf "%-20s %s\n" "Service" "URL"
printf "%-20s %s\n" "--------------------" "--------------------------------"

printf "%-20s %s\n" "UI" "http://localhost:8080"
printf "%-20s %s\n" "Catalog" "http://localhost:8081"
printf "%-20s %s\n" "Cart" "http://localhost:8082"
printf "%-20s %s\n" "Orders" "http://localhost:8083"
printf "%-20s %s\n" "Checkout" "http://localhost:8084"

printf "%-20s %s\n" "Grafana" "http://localhost:3000"
printf "%-20s %s\n" "Prometheus" "http://localhost:9090"
printf "%-20s %s\n" "AlertManager" "http://localhost:9093"

printf "%-20s %s\n" "ArgoCD" "https://localhost:8888"
printf "%-20s %s\n" "Ingress" "http://localhost:8090"

echo
echo "Press Ctrl+C to stop all port-forwards..."

wait