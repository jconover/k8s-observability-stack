# Deployment Guide

## Prerequisites

- Kubernetes cluster (1.25+)
- Helm 3.10+
- kubectl configured
- Sufficient resources:
  - 8GB RAM minimum
  - 100GB storage for metrics
  - 3+ nodes for HA setup

## Installation Steps

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/k8s-observability-stack.git
cd k8s-observability-stack
```

### 2. Configure Values
Edit `helm/values.yaml`:
- Set Slack webhook URL
- Configure retention periods
- Adjust resource limits
- Set ingress domains

### 3. Install Stack
```bash
make install
```

### 4. Verify Installation
```bash
kubectl get pods -n monitoring
```

### 5. Access Dashboards
```bash
make port-forward
# Open http://localhost:3000
```

## Environment Configurations

### Development
- Minimal resources
- 7-day retention
- Single replicas

### Staging
- Moderate resources
- 14-day retention
- Some HA features

### Production
- Full resources
- 30-day retention
- Complete HA setup
