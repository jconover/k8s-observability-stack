### **Makefile**
```makefile
.PHONY: help install uninstall upgrade test lint deploy clean

NAMESPACE := monitoring
RELEASE_NAME := observability-stack
HELM_CHART := ./helm

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install the observability stack
	@echo "Installing observability stack..."
	helm install $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--values $(HELM_CHART)/values.yaml

uninstall: ## Uninstall the observability stack
	@echo "Uninstalling observability stack..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	kubectl delete namespace $(NAMESPACE) --ignore-not-found

upgrade: ## Upgrade the observability stack
	@echo "Upgrading observability stack..."
	helm upgrade $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--values $(HELM_CHART)/values.yaml

test-unit: ## Run unit tests
	@echo "Running unit tests..."
	go test ./tests/unit/...

test-integration: ## Run integration tests
	@echo "Running integration tests..."
	go test ./tests/integration/...

test-e2e: ## Run end-to-end tests
	@echo "Running e2e tests..."
	go test ./tests/e2e/...

test: test-unit test-integration ## Run all tests

lint: ## Lint Kubernetes manifests
	@echo "Linting Kubernetes manifests..."
	yamllint kubernetes/
	helm lint $(HELM_CHART)

validate: ## Validate Kubernetes manifests
	@echo "Validating Kubernetes manifests..."
	kubectl apply --dry-run=client -f kubernetes/base/

port-forward: ## Port forward to Grafana
	@echo "Port forwarding to Grafana..."
	kubectl port-forward -n $(NAMESPACE) svc/grafana 3000:80

logs-prometheus: ## Show Prometheus logs
	kubectl logs -n $(NAMESPACE) -l app=prometheus --tail=100 -f

logs-grafana: ## Show Grafana logs
	kubectl logs -n $(NAMESPACE) -l app=grafana --tail=100 -f

logs-loki: ## Show Loki logs
	kubectl logs -n $(NAMESPACE) -l app=loki --tail=100 -f

backup: ## Backup Prometheus data
	@echo "Backing up Prometheus data..."
	./scripts/backup-prometheus.sh

restore: ## Restore Prometheus data
	@echo "Restoring Prometheus data..."
	./scripts/restore-prometheus.sh

clean: ## Clean up generated files
	@echo "Cleaning up..."
	rm -rf .tmp/
	rm -rf .build/

deploy-dev: ## Deploy to development
	@echo "Deploying to development..."
	helm upgrade --install $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE)-dev \
		--create-namespace \
		--values $(HELM_CHART)/values-dev.yaml

deploy-staging: ## Deploy to staging
	@echo "Deploying to staging..."
	helm upgrade --install $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE)-staging \
		--create-namespace \
		--values $(HELM_CHART)/values-staging.yaml

deploy-production: ## Deploy to production
	@echo "Deploying to production..."
	helm upgrade --install $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--values $(HELM_CHART)/values-production.yaml