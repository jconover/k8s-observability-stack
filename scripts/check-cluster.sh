#!/bin/bash

# Script to check if your cluster can handle the monitoring stack

echo "🔍 Kubernetes Cluster Diagnostic"
echo "================================"
echo ""

echo "1️⃣ Cluster Information:"
echo "------------------------"
kubectl cluster-info
echo ""

echo "2️⃣ Nodes Status:"
echo "----------------"
kubectl get nodes -o wide
echo ""

echo "3️⃣ Node Resources:"
echo "------------------"
kubectl describe nodes | grep -A 5 "Allocated resources:"
echo ""

echo "4️⃣ Current Pods in All Namespaces:"
echo "-----------------------------------"
kubectl get pods --all-namespaces | wc -l
echo "Total pods running: $(kubectl get pods --all-namespaces | wc -l)"
echo ""

echo "5️⃣ Monitoring Namespace Status:"
echo "--------------------------------"
kubectl get all -n monitoring 2>/dev/null || echo "Monitoring namespace not found or empty"
echo ""

echo "6️⃣ Failed Pods in Monitoring:"
echo "------------------------------"
kubectl get pods -n monitoring --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null
echo ""

echo "7️⃣ Recent Events in Monitoring Namespace:"
echo "------------------------------------------"
kubectl get events -n monitoring --sort-by='.lastTimestamp' 2>/dev/null | tail -20
echo ""

echo "8️⃣ Storage Classes Available:"
echo "-----------------------------"
kubectl get storageclass
echo ""

echo "9️⃣ Check for Resource Pressure:"
echo "--------------------------------"
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="MemoryPressure")].status}{"\t"}{.status.conditions[?(@.type=="DiskPressure")].status}{"\t"}{.status.conditions[?(@.type=="PIDPressure")].status}{"\n"}{end}' | column -t -s $'\t' -N "NODE,MEMORY_PRESSURE,DISK_PRESSURE,PID_PRESSURE"
echo ""

echo "🔟 Helm Releases:"
echo "----------------"
helm list --all-namespaces
echo ""

echo "📊 Diagnosis Summary:"
echo "--------------------"

# Check if cluster is too small
TOTAL_CPU=$(kubectl get nodes -o jsonpath='{.items[*].status.capacity.cpu}' | tr ' ' '\n' | awk '{s+=$1} END {print s}')
TOTAL_MEM=$(kubectl get nodes -o jsonpath='{.items[*].status.capacity.memory}' | tr ' ' '\n' | sed 's/Ki$//' | awk '{s+=$1} END {print s/1024/1024}')

echo "Total Cluster CPU: ${TOTAL_CPU:-Unknown} cores"
echo "Total Cluster Memory: ${TOTAL_MEM:-Unknown} GB"
echo ""

if [[ -n "$TOTAL_CPU" ]] && [[ "$TOTAL_CPU" -lt 2 ]]; then
  echo "⚠️  WARNING: Your cluster has less than 2 CPU cores."
  echo "   The full monitoring stack requires at least 2 cores."
  echo "   Use the lightweight installation instead."
elif [[ -n "$TOTAL_MEM" ]] && (( $(echo "$TOTAL_MEM < 4" | bc -l) )); then
  echo "⚠️  WARNING: Your cluster has less than 4GB memory."
  echo "   The full monitoring stack requires at least 4GB."
  echo "   Use the lightweight installation instead."
else
  echo "✅ Cluster appears to have sufficient resources."
fi

echo ""
echo "💡 Recommendations:"
echo "------------------"
echo "1. If resources are limited, use: ./lightweight-install.sh"
echo "2. If pods are pending, check: kubectl describe pod <pod-name> -n monitoring"
echo "3. If pods are crashing, check: kubectl logs <pod-name> -n monitoring"
echo "4. For timeout issues, try installing components one at a time"