#!/bin/bash

# Direct installation of monitoring stack without custom Helm chart
# This installs the components directly from their official charts

set -e

NAMESPACE="monitoring"

echo "🚀 Installing Kubernetes Observability Stack (Direct Method)..."
echo "============================================================"

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
echo "📚 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
echo ""
echo "📊 Installing Prometheus Stack..."
echo "--------------------------------"
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --set grafana.enabled=true \
  --set grafana.adminPassword=admin123 \
  --set grafana.persistence.enabled=false \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=1Gi \
  --set prometheusOperator.admissionWebhooks.enabled=false \
  --wait \
  --timeout 10m

# Install Loki
echo ""
echo "📝 Installing Loki Stack..."
echo "-------------------------"
helm upgrade --install loki grafana/loki-stack \
  --namespace $NAMESPACE \
  --set loki.persistence.enabled=false \
  --set promtail.enabled=true \
  --set grafana.enabled=false \
  --wait \
  --timeout 5m

# Wait for pods
echo ""
echo "⏳ Waiting for pods to be ready..."
sleep 10

# Show pod status
echo ""
echo "📊 Pod Status:"
echo "-------------"
kubectl get pods -n $NAMESPACE

echo ""
echo "✅ Installation Complete!"
echo "========================"
echo ""

# Get Grafana password
GRAFANA_PASSWORD=$(kubectl get secret --namespace $NAMESPACE prometheus-stack-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode || echo "admin123")

echo "📊 Access Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-stack-grafana 80:80"
echo "   URL: http://localhost"
echo "   Username: admin"
echo "   Password: $GRAFANA_PASSWORD"
echo ""

echo "🔍 Access Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-stack-kube-prom-prometheus 9090:9090"
echo "   URL: http://localhost:9090"
echo ""

echo "🔔 Access AlertManager:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-stack-kube-prom-alertmanager 9093:9093"
echo "   URL: http://localhost:9093"
echo ""

echo "📝 Configure Loki in Grafana:"
echo "   1. Access Grafana"
echo "   2. Go to Configuration > Data Sources"
echo "   3. Add Loki data source"
echo "   4. URL: http://loki:3100"
echo ""

echo "🗑️  To uninstall everything:"
echo "   helm uninstall prometheus-stack -n $NAMESPACE"
echo "   helm uninstall loki -n $NAMESPACE"
echo "   kubectl delete namespace $NAMESPACE"