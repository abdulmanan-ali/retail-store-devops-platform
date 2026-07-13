#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# Retail Store Health Check Script
# ==========================================

# Service ports
declare -A SERVICES=(
    ["ui"]=8080
    ["catalog"]=8081
    ["cart"]=8082
    ["orders"]=8083
    ["checkout"]=8084
)

passed=0
failed=0

echo "======================================"
echo " Retail Store Health Check"
echo "======================================"

for service in "${!SERVICES[@]}"; do
    port="${SERVICES[$service]}"

    # Determine endpoint
    if [[ "$service" == "catalog" ]]; then
        endpoint="http://localhost:${port}/"
    elif [[ "$service" == "checkout" ]]; then
        endpoint="http://localhost:${port}/health"
    else
        endpoint="http://localhost:${port}/actuator/health"
    fi
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$endpoint" 2>/dev/null)
    if [[ -z "$status_code" ]]; then
    status_code="000"
    fi

    if [[ "$status_code" == "200" ]]; then
        echo "✅ $service - healthy"
        passed=$((passed + 1))
    else
        echo "❌ $service - UNHEALTHY (got: $status_code)"
        failed=$((failed + 1))
    fi
done

echo
echo "======================================"
echo "Summary"
echo "======================================"
echo "Passed: $passed"
echo "Failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
else
    exit 0
fi