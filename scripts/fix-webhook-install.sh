#!/bin/bash

# Fix script for admission webhook issues

set -e

NAMESPACE="monitoring"

echo "🔧 Fixing Admission Webhook Issues..."
echo "====================================="
echo ""

echo "1️⃣ Cleaning up existing installation..."
echo "----------------------------------------"

# Delete the problematic resources
echo "Removing existing Helm release..."
helm uninstall prometheus-stack -n $NAMESPACE 2>/dev/null || true

echo "Cleaning up leftover resources..."
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io prometheus-stack-kube-prom-admission 2>/dev/null || true
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io prometheus-stack-kube-prom-admission 2>/dev/null || true
kubectl delete jobs -n $NAMESPACE -l app.kubernetes.io/name=kube-prometheus-stack 2>/dev/null || true
kubectl delete pods -n $NAMESPACE -l app.kubernetes.io/name=kube-prometheus-stack 2>/dev/null || true
kubectl delete secrets -n $NAMESPACE prometheus-stack-kube-prom-admission 2>/dev/null || true

echo "Waiting for cleanup..."
sleep 5

echo ""
echo "2️⃣ Installing with webhooks completely disabled..."
echo "---------------------------------------------------"

# Create a comprehensive values file that disables all webhook-related features
cat > /tmp/no-webhook-values.yaml << 'EOF'
# Completely disable admission webhooks
prometheusOperator:
  admissionWebhooks:
    enabled: false
    patch:
      enabled: false
    certManager:
      enabled: false
  tls:
    enabled: false
  resources:
    requests:
      cpu: 100m
      memory: 100Mi
    limits:
      cpu: 200m
      memory: 200Mi

# Minimal Prometheus configuration
prometheus:
  prometheusSpec:
    retention: 1d
    resources:
      requests:
        cpu: 200m
        memory: 400Mi
      limits:
        cpu: 500m
        memory: 1Gi
    # No persistent storage for now
    storageSpec: {}
    # Disable service monitors that might cause issues
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false

# Minimal Grafana configuration  
grafana:
  enabled: true
  adminPassword: "admin123"
  persistence:
    enabled: false
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  # Add Prometheus as default datasource
  sidecar:
    dashboards:
      enabled: true
    datasources:
      enabled: true
      defaultDatasourceEnabled: true

# Minimal AlertManager
alertmanager:
  enabled: true
  alertmanagerSpec:
    storage: {}
    resources:
      requests:
        cpu: 50m
        memory: 50Mi
      limits:
        cpu: 100m
        memory: 100Mi

# Disable components we don't need for basic setup
kubeApiServer:
  enabled: true
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeProxy:
  enabled: false
kubeEtcd:
  enabled: false
kubelet:
  enabled: true

# Node exporter with minimal resources
nodeExporter:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 30Mi
    limits:
      cpu: 100m
      memory: 50Mi

# Kube-state-metrics with minimal resources
kubeStateMetrics:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 50Mi
    limits:
      cpu: 100m
      memory: 100Mi

# Disable Prometheus Node Exporter's service monitor for now
prometheus-node-exporter:
  prometheus:
    monitor:
      enabled: false

# Global settings
global:
  rbac:
    create: true
    pspEnabled: false

# Common labels
commonLabels:
  prometheus: kube-prometheus
EOF

echo "Installing kube-prometheus-stack..."
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --create-namespace \
  --values /tmp/no-webhook-values.yaml \
  --version 45.7.1 \
  --timeout 10m \
  --wait=false

echo ""
echo "3️⃣ Verifying installation..."
echo "-----------------------------"
sleep 5

echo "Checking for webhook configurations (should be empty):"
kubectl get validatingwebhookconfigurations | grep prometheus || echo "✅ No validating webhooks found"
kubectl get mutatingwebhookconfigurations | grep prometheus || echo "✅ No mutating webhooks found"

echo ""
echo "Checking pods status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "Checking for any errors:"
kubectl get events -n $NAMESPACE --field-selector type=Warning --sort-by='.lastTimestamp' | tail -5 || echo "No recent warnings"

echo ""
echo "✅ Installation completed!"
echo "========================="
echo ""
echo "⏳ Pods are starting up. Monitor with:"
echo "   watch kubectl get pods -n $NAMESPACE"
echo ""
echo "📊 Once pods are Running, access services:"
echo ""
echo "Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-stack-grafana 3000:80"
echo "   URL: http://localhost:3000"
echo "   Login: admin / admin123"
echo ""
echo "Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-stack-kube-prom-prometheus 9090:9090"
echo "   URL: http://localhost:9090"
echo ""
echo "AlertManager:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-stack-kube-prom-alertmanager 9093:9093"
echo "   URL: http://localhost:9093"
echo ""
echo "🔍 Troubleshooting:"
echo "   kubectl describe pod <pod-name> -n $NAMESPACE"
echo "   kubectl logs <pod-name> -n $NAMESPACE"
