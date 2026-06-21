#!/bin/bash
set -e

echo "Starting port-forwards..."
kubectl port-forward svc/ui -n retail-store 8080:8080 &
PF1=$!
kubectl port-forward svc/catalog -n retail-store 8081:8080 &
PF2=$!
kubectl port-forward svc/cart -n retail-store 8083:8080 &
PF3=$!
kubectl port-forward svc/orders -n retail-store 8084:8080 &
PF4=$!
kubectl port-forward svc/checkout -n retail-store 8085:8080 &
PF5=$!

sleep 5

echo "=== Load testing UI ==="
hey -z 30s -c 15 http://localhost:8080/ &

echo "=== Load testing Catalog products ==="
hey -z 30s -c 15 http://localhost:8081/catalog/products &

echo "=== Load testing Cart ==="
hey -z 30s -c 10 http://localhost:8083/carts/u1 &

echo "=== Load testing Orders ==="
hey -z 30s -c 10 http://localhost:8084/orders/u1 &

wait

echo "Load test complete."
echo "Cleaning up load-test port-forwards only..."
# kill $(lsof -t -i:8080) $(lsof -t -i:8081) $(lsof -t -i:8083) $(lsof -t -i:8084) $(lsof -t -i:8085) 2>/dev/null
sed -i 's/kill \$PF1 \$PF2 \$PF3 \$PF4 \$PF5 2>\/dev\/null/kill $(lsof -t -i:8080) $(lsof -t -i:8081) $(lsof -t -i:8083) $(lsof -t -i:8084) $(lsof -t -i:8085) 2>\/dev\/null/' devops/scripts/load-test.sh
echo "Done."