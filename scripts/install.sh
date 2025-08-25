#!/bin/bash

set -e

NAMESPACE="monitoring"
RELEASE_NAME="observability-stack"

echo "🚀 Installing Kubernetes Observability Stack..."

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm is required but not installed." >&2; exit 1; }

# Check cluster connection
echo "🔍 Checking cluster connection..."
kubectl cluster-info >/dev/null 2>&1 || { echo "❌ Cannot connect to Kubernetes cluster." >&2; exit 1; }

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo "📚 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Install the stack
echo "🔧 Installing observability stack..."
helm upgrade --install $RELEASE_NAME ./helm \
    --namespace $NAMESPACE \
    --values ./helm/values.yaml \
    --wait \
    --timeout 10m

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=prometheus \
    -n $NAMESPACE \
    --timeout=300s

kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=grafana \
    -n $NAMESPACE \
    --timeout=300s

# Get Grafana password
GRAFANA_PASSWORD=$(kubectl get secret --namespace $NAMESPACE ${RELEASE_NAME}-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo ""
echo "✅ Installation complete!"
echo ""
echo "📊 Access Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/${RELEASE_NAME}-grafana 3000:80"
echo "   URL: http://localhost:3000"
echo "   Username: admin"
echo "   Password: $GRAFANA_PASSWORD"
echo ""
echo "🔍 Access Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/${RELEASE_NAME}-prometheus 9090:9090"
echo "   URL: http://localhost:9090"
echo ""
echo "📝 Check pod status:"
echo "   kubectl get pods -n $NAMESPACE"