#!/bin/bash

set -e

NAMESPACE="monitoring"
RELEASE_NAME="observability-stack"

echo "🗑️ Uninstalling Kubernetes Observability Stack..."

# Uninstall Helm release
helm uninstall $RELEASE_NAME --namespace $NAMESPACE 2>/dev/null || true

# Delete namespace
kubectl delete namespace $NAMESPACE --ignore-not-found

echo "✅ Uninstallation complete!"
