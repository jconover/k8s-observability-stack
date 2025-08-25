#!/bin/bash

# Debug script to identify the exact issue

echo "🔍 Debugging Helm Installation Issue"
echo "===================================="

echo ""
echo "1. Checking Helm version:"
helm version

echo ""
echo "2. Checking current directory structure:"
ls -la helm/

echo ""
echo "3. Checking if charts were downloaded:"
ls -la helm/charts/ 2>/dev/null || echo "No charts directory found"

echo ""
echo "4. Testing template rendering:"
helm template test ./helm --debug 2>&1 | head -50

echo ""
echo "5. Checking for specific issues in values:"
echo "Validating YAML syntax..."
helm lint ./helm

echo ""
echo "6. Try dry-run installation:"
helm install observability-stack ./helm \
  --namespace monitoring \
  --dry-run \
  --debug 2>&1 | grep -A5 -B5 "error\|Error\|unable"

echo ""
echo "7. Clean up any existing failed releases:"
helm list -n monitoring -a
echo ""
echo "If you see a failed release above, run:"
echo "  helm uninstall observability-stack -n monitoring"

echo ""
echo "8. Alternative: Install components separately:"
echo "  ./direct-install.sh"