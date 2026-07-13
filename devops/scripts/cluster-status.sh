#!/usr/bin/env bash

# Check kubectl
if ! command -v kubectl >/dev/null 2>&1; then
    echo "❌ Error: kubectl is not installed."
    exit 1
fi

# Check cluster
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Error: Unable to connect to the Kubernetes cluster."
    exit 1
fi

get_ready_pods() {
    kubectl get pods -n "$1" --no-headers |
    awk '
    {
        split($2, ready, "/")
        if (ready[1] == ready[2])
            count++
    }
    END {
        print count + 0
    }'
}

echo "======================================"
echo " Retail Store Cluster Status"
echo "======================================"
echo

echo "📦 Nodes"
kubectl get nodes
echo

echo "🚀 Retail Store Pods"
kubectl get pods -n retail-store
echo

total_pods=$(kubectl get pods -n retail-store --no-headers | awk 'END{print NR}')
ready_pods=$(get_ready_pods retail-store)
echo "Ready Pods: ${ready_pods}/${total_pods}"
echo

echo "📈 Horizontal Pod Autoscalers"
kubectl get hpa -n retail-store
echo

echo "🌐 Ingress"
kubectl get ingress -n retail-store
echo

echo "🔄 ArgoCD Applications"
kubectl get application -n argocd
echo

echo "📊 Monitoring"
monitoring_total=$(kubectl get pods -n monitoring --no-headers | awk 'END{print NR}')
monitoring_ready=$(get_ready_pods monitoring)
echo "Ready Pods: ${monitoring_ready}/${monitoring_total}"
echo

if [[ "$ready_pods" -eq "$total_pods" ]]; then
    echo "Cluster healthy ✅"
    exit 0
else
    echo "Issues detected ❌"
    exit 1
fi