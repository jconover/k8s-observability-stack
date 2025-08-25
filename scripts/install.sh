#!/bin/bash

set -e

NAMESPACE="monitoring"
RELEASE_NAME="observability-stack"

echo "🚀 Installing Kubernetes Observability Stack..."

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm is required." >&2; exit 1; }

# Check cluster connection
echo "🔍 Checking cluster connection..."
kubectl cluster-info >/dev/null 2>&1 || { echo "❌ Cannot connect to cluster." >&2; exit 1; }

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo "📚 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts || true
helm repo update

# Build Helm dependencies
echo "📦 Building Helm dependencies..."
cd helm
helm dependency build
cd ..

# Install the stack
echo "🔧 Installing observability stack..."
helm upgrade --install $RELEASE_NAME ./helm \
    --namespace $NAMESPACE \
    --values ./helm/values.yaml \
    --wait \
    --timeout 10m

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
sleep 10

# Get pod status
echo "📊 Current pod status:"
kubectl get pods -n $NAMESPACE

# Try to get Grafana password
echo ""
echo "✅ Installation complete!"
echo ""
echo "📊 Access Instructions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get Grafana service name and password
GRAFANA_SERVICE=$(kubectl get svc -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "grafana")
GRAFANA_PASSWORD=$(kubectl get secret --namespace $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath="{.items[0].data.admin-password}" 2>/dev/null | base64 --decode || echo "Check helm values.yaml")

echo "🔐 Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/$GRAFANA_SERVICE 3000:80"
echo "   URL: http://localhost:3000"
echo "   Username: admin"
echo "   Password: $GRAFANA_PASSWORD"
echo ""

# Get Prometheus service name
PROMETHEUS_SERVICE=$(kubectl get svc -n $NAMESPACE -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "prometheus")
echo "📈 Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/$PROMETHEUS_SERVICE 9090:9090"
echo "   URL: http://localhost:9090"
echo ""

# Get AlertManager service name
ALERTMANAGER_SERVICE=$(kubectl get svc -n $NAMESPACE -l app.kubernetes.io/name=alertmanager -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "alertmanager")
echo "🔔 AlertManager:"
echo "   kubectl port-forward -n $NAMESPACE svc/$ALERTMANAGER_SERVICE 9093:9093"
echo "   URL: http://localhost:9093"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Useful commands:"
echo "   Check status:  kubectl get pods -n $NAMESPACE"
echo "   View logs:     kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=prometheus"
echo "   Uninstall:     helm uninstall $RELEASE_NAME -n $NAMESPACE"