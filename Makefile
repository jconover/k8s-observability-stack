.PHONY: help install uninstall upgrade test lint deploy clean port-forward

NAMESPACE := monitoring
RELEASE_NAME := observability-stack
HELM_CHART := ./helm

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install the observability stack
	@echo "Installing observability stack..."
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm repo add grafana https://grafana.github.io/helm-charts
	@helm repo update
	@helm install $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--values $(HELM_CHART)/values.yaml

uninstall: ## Uninstall the observability stack
	@echo "Uninstalling observability stack..."
	@helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found

upgrade: ## Upgrade the observability stack
	@echo "Upgrading observability stack..."
	@helm upgrade $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--values $(HELM_CHART)/values.yaml

port-forward: ## Port forward to Grafana
	@echo "Port forwarding to Grafana on http://localhost:3000"
	@kubectl port-forward -n $(NAMESPACE) svc/grafana 3000:80

status: ## Check status of monitoring components
	@kubectl get pods -n $(NAMESPACE)

logs-prometheus: ## Show Prometheus logs
	@kubectl logs -n $(NAMESPACE) -l app=prometheus --tail=100 -f

logs-grafana: ## Show Grafana logs
	@kubectl logs -n $(NAMESPACE) -l app=grafana --tail=100 -f

clean: ## Clean up generated files
	@rm -rf .tmp/ .build/ *.tgz
