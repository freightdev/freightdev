// scripts/deploy.sh
#!/bin/bash

set -e

# Deployment script for Payment Service
ENVIRONMENT=${ENVIRONMENT:-"staging"}
VERSION=${VERSION:-$(git rev-parse --short HEAD)}
NAMESPACE="payment-service-${ENVIRONMENT}"

echo "Deploying Payment Service v${VERSION} to ${ENVIRONMENT}"

# Build and push Docker image
echo "Building Docker image..."
docker build -t payment-service:${VERSION} -f docker/Dockerfile .
docker tag payment-service:${VERSION} payment-service:latest

# Push to registry (replace with your registry)
if [ "$ENVIRONMENT" = "production" ]; then
    echo "Pushing to production registry..."
    docker tag payment-service:${VERSION} your-registry.com/payment-service:${VERSION}
    docker push your-registry.com/payment-service:${VERSION}
fi

# Apply Kubernetes manifests
echo "Deploying to Kubernetes..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Update image version in deployment
sed "s/IMAGE_VERSION/${VERSION}/g" deployments/k8s/deployment.yaml | kubectl apply -n ${NAMESPACE} -f -
kubectl apply -n ${NAMESPACE} -f deployments/k8s/

# Wait for deployment to complete
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/payment-service -n ${NAMESPACE} --timeout=300s

# Run health check
echo "Running health check..."
kubectl port-forward -n ${NAMESPACE} svc/payment-service 8080:80 &
PF_PID=$!
sleep 5

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
kill $PF_PID

if [ "$HEALTH_CHECK" = "200" ]; then
    echo "✅ Deployment successful! Service is healthy."
else
    echo "❌ Health check failed. HTTP status: $HEALTH_CHECK"
    exit 1
fi

echo "🚀 Payment Service v${VERSION} deployed successfully to ${ENVIRONMENT}"

# Optional: Run smoke tests
if [ "$ENVIRONMENT" = "staging" ]; then
    echo "Running smoke tests..."
    ./scripts/smoke_test.sh
fi
