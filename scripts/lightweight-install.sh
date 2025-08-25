#!/bin/bash

# Lightweight installation with minimal resources
# Suitable for development/testing clusters with limited resources

set -e

NAMESPACE="monitoring"

echo "🚀 Installing Lightweight Monitoring Stack..."
echo "============================================"
echo ""

# Check cluster resources first
echo "📊 Checking cluster resources..."
echo "--------------------------------"
kubectl get nodes -o wide
echo ""
kubectl top nodes 2>/dev/null || echo "Note: Metrics server not installed, cannot show resource usage"
echo ""

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add repos
echo "📚 Updating Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create minimal values file
echo "📝 Creating minimal configuration..."
cat > /tmp/minimal-monitoring-values.yaml << 'EOF'
# Minimal resource configuration
prometheusOperator:
  admissionWebhooks:
    enabled: false
  resources:
    requests:
      cpu: 50m
      memory: 100Mi
    limits:
      cpu: 200m
      memory: 200Mi

prometheus:
  prometheusSpec:
    retention: 1d
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi
    storageSpec: {}  # No persistent storage for minimal setup

alertmanager:
  enabled: false  # Disable AlertManager for minimal setup

grafana:
  enabled: true
  adminPassword: "admin"
  resources:
    requests:
      cpu: 50m
      memory: 100Mi
    limits:
      cpu: 200m
      memory: 200Mi
  persistence:
    enabled: false

# Disable heavy components
kubeEtcd:
  enabled: false
kubeScheduler:
  enabled: false
kubeControllerManager:
  enabled: false
kubeProxy:
  enabled: false

# Reduce node-exporter resources
nodeExporter:
  resources:
    requests:
      cpu: 10m
      memory: 20Mi
    limits:
      cpu: 50m
      memory: 50Mi

# Reduce kube-state-metrics resources
kubeStateMetrics:
  resources:
    requests:
      cpu: 10m
      memory: 50Mi
    limits:
      cpu: 100m
      memory: 100Mi
EOF

echo ""
echo "📊 Installing Prometheus Stack (Minimal)..."
echo "-------------------------------------------"
echo "This will install with very low resource requirements..."
echo ""

helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --values /tmp/minimal-monitoring-values.yaml \
  --timeout 15m \
  --wait=false

echo ""
echo "⏳ Waiting for deployment to start..."
sleep 5

echo ""
echo "📊 Checking pod status..."
echo "-------------------------"
kubectl get pods -n $NAMESPACE

echo ""
echo "📝 Checking for any issues..."
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10

echo ""
echo "🔍 Checking pod details..."
for pod in $(kubectl get pods -n $NAMESPACE -o name | head -3); do
  echo ""
  echo "Pod: $pod"
  kubectl describe $pod -n $NAMESPACE | grep -A 5 "Events:" | head -10
done

echo ""
echo "✅ Installation initiated!"
echo "========================="
echo ""
echo "⏳ Pods may take a few minutes to become ready."
echo ""
echo "📊 Monitor the installation:"
echo "   watch kubectl get pods -n $NAMESPACE"
echo ""
echo "📊 Once pods are running, access Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-stack-grafana 3000:80"
echo "   URL: http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "🔍 Access Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-stack-kube-prom-prometheus 9090:9090"
echo "   URL: http://localhost:9090"
echo ""
echo "🗑️  To uninstall:"
echo "   helm uninstall prometheus-stack -n $NAMESPACE"
echo "   kubectl delete namespace $NAMESPACE"
echo ""
echo "⚠️  Note: This is a minimal setup suitable for development/testing."
echo "   For production, increase resources and enable persistence."