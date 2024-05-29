# Folders
LOCALBIN ?= $(shell pwd)/bin

# Dependencies
CERTMANAGER_VERSION ?= 1.10.0
CMCTL = $(LOCALBIN)/cmctl
OPENTELEMETRY_OPERATOR_VERSION ?= 0.101.0
TEMPO_OPERATOR_VERSION ?= 0.10.0
PROMETHEUS_OPERATOR_VERSION ?= 0.74.0

ISTIOCTL ?= $(LOCALBIN)/istioctl
ISTIO_VERSION ?= "1.15.0"


help: ## Show help message
	@printf "Kiali and distributed tracing tutorial\n"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  %-15s \t\t%s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: start-cluster
start-cluster: ## Start kind cluster
	kind create cluster --name=workshop --config=kind.yaml

.PHONY: clean
clean: ## Clean all the resources
	kind delete cluster --name=workshop
	rm -rf $(LOCALBIN)


.PHONY: dependencies
dependencies: ## Deploy all the dependencies in the cluster
dependencies: cert-manager opentelemetry-operator tempo-operator istio kiali-operator prometheus-operator

.PHONY: cert-manager
cert-manager: ## Deploy cert-manager
	@{ \
	set -e ;\
	if (`pwd`/bin/cmctl version | grep ${CERTMANAGER_VERSION}) > /dev/null 2>&1 ; then \
		exit 0; \
	fi ;\
	TMP_DIR=$$(mktemp -d) ;\
	curl -L -o $$TMP_DIR/cmctl.tar.gz https://github.com/jetstack/cert-manager/releases/download/v$(CERTMANAGER_VERSION)/cmctl-`go env GOOS`-`go env GOARCH`.tar.gz ;\
	tar xzf $$TMP_DIR/cmctl.tar.gz -C $$TMP_DIR ;\
	[ -d bin ] || mkdir bin ;\
	mv $$TMP_DIR/cmctl $(CMCTL) ;\
	rm -rf $$TMP_DIR ;\
	}
	kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v${CERTMANAGER_VERSION}/cert-manager.yaml
	$(CMCTL) check api --wait=5m

.PHONY: opentelemetry-operator
opentelemetry-operator: ## Deploy the OpenTelemetry operator
	kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v$(OPENTELEMETRY_OPERATOR_VERSION)/opentelemetry-operator.yaml

.PHONY: tempo-operator
tempo-operator: ## Deploy the Tempo operator
	kubectl apply -f https://github.com/grafana/tempo-operator/releases/download/v$(TEMPO_OPERATOR_VERSION)/tempo-operator.yaml

.PHONY: istio
istio: ## Deploy istio
	curl -sLo $(LOCALBIN)/downloadIstio https://istio.io/downloadIstio
	chmod +x $(LOCALBIN)/downloadIstio
	ISTIO_VERSION=$(ISTIO_VERSION) $(LOCALBIN)/downloadIstio
	mv istio-$(ISTIO_VERSION) $(LOCALBIN)
	$(LOCALBIN)/istio-$(ISTIO_VERSION)/bin/istioctl install --set profile=minimal -y

.PHONY: kiali-operator
kiali-operator: ## Deploy the Kiali operator
	helm repo add kiali https://kiali.org/helm-charts
	helm install --namespace kiali-operator --create-namespace kiali-operator kiali/kiali-operator

.PHONY: prometheus-operator
prometheus-operator: ## Deploy the Prometheus operator
	kubectl create -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v$(PROMETHEUS_OPERATOR_VERSION)/bundle.yaml
