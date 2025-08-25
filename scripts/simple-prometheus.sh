#!/bin/bash

# Simplest possible monitoring setup - just Prometheus and Grafana
# No operators, no webhooks, no CRDs

set -e

NAMESPACE="monitoring"

echo "🚀 Installing Simple Prometheus + Grafana Setup..."
echo "================================================"
echo ""

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo ""
echo "1️⃣ Installing Prometheus Server (without operator)..."
echo "------------------------------------------------------"

helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace $NAMESPACE \
  --set alertmanager.enabled=false \
  --set prometheus-pushgateway.enabled=false \
  --set server.persistentVolume.enabled=false \
  --set server.resources.requests.cpu=200m \
  --set server.resources.requests.memory=256Mi \
  --set server.resources.limits.cpu=500m \
  --set server.resources.limits.memory=512Mi \
  --wait=false

echo ""
echo "2️⃣ Installing Grafana..."
echo "------------------------"

helm upgrade --install grafana grafana/grafana \
  --namespace $NAMESPACE \
  --set adminPassword=admin123 \
  --set persistence.enabled=false \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi \
  --set resources.limits.cpu=200m \
  --set resources.limits.memory=256Mi \
  --wait=false

echo ""
echo "3️⃣ Waiting for pods to start..."
echo "--------------------------------"
sleep 10

kubectl get pods -n $NAMESPACE

echo ""
echo "✅ Simple Monitoring Stack Installed!"
echo "====================================="
echo ""
echo "📊 Access Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo "   URL: http://localhost:3000"
echo "   Login: admin / admin123"
echo ""
echo "🔍 Access Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-server 9090:80"
echo "   URL: http://localhost:9090"
echo ""
echo "➕ Add Prometheus to Grafana:"
echo "   1. Login to Grafana"
echo "   2. Go to Configuration > Data Sources"
echo "   3. Add Prometheus"
echo "   4. URL: http://prometheus-server.monitoring.svc.cluster.local"
echo "   5. Click 'Save & Test'"
echo ""
echo "📈 Import dashboards:"
echo "   1. Go to Dashboards > Import"
echo "   2. Enter dashboard ID: 3662 (for Kubernetes cluster monitoring)"
echo "   3. Select Prometheus datasource"
echo "   4. Click Import"
echo ""
echo "🗑️ To uninstall:"
echo "   helm uninstall prometheus -n $NAMESPACE"
echo "   helm uninstall grafana -n $NAMESPACE"
echo "   kubectl delete namespace $NAMESPACE"
