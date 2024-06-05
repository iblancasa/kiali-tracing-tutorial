# Folders
LOCALBIN ?= $(shell pwd)/bin

# Dependencies
CERTMANAGER_VERSION ?= 1.10.0
CMCTL = $(LOCALBIN)/cmctl
OPENTELEMETRY_OPERATOR_VERSION ?= 0.101.0
JAEGER_OPERATOR_VERSION ?= 1.57.0

ISTIOCTL ?= $(LOCALBIN)/istioctl
ISTIO_VERSION ?= "1.22.0"

# Applications
APP_IMG ?= ttl.sh/iblancasa/demo-app1
APP2_IMG ?= ttl.sh/iblancasa/demo-app2
APP3_IMG ?= ttl.sh/iblancasa/demo-app3


help: ## Show help message
	@printf "Kiali and distributed tracing tutorial\n"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  %-15s \t\t%s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

################## Cluster management ###########################################################################################
.PHONY: start-cluster
start-cluster: ## Start kind cluster
	kind create cluster --name=workshop --config=kind.yaml
	kubectl create -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.1/deploy/static/provider/kind/deploy.yaml

.PHONY: clean
clean: ## Clean all the resources
	kind delete cluster --name=workshop
	rm -rf $(LOCALBIN)

################## Install dependencies #########################################################################################
.PHONY: dependencies
dependencies: ## Deploy all the dependencies in the cluster
dependencies: cert-manager opentelemetry-operator jaeger-operator kiali-operator

.PHONY: cert-manager
cert-manager: ## Deploy cert-manager
	mkdir -p $(LOCALBIN)
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

.PHONY: jaeger-operator
jaeger-operator: ## Deploy the Jaeger operator
	kubectl create namespace observability 2>&1 | grep -v "already exists" || true
	kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v$(JAEGER_OPERATOR_VERSION)/jaeger-operator.yaml

################## Infrastructure management ####################################################################################
.PHONY: infra
infra: ## Deploy the needed infrastructure
infra: istio
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/prometheus.yaml
	kubectl apply -f infra/otelcol.yaml
	kubectl apply -f infra/jaeger.yaml
	kubectl apply -f infra/kiali.yaml

.PHONY: istio
istio: ## Deploy istio
	mkdir -p $(LOCALBIN)
	curl -sLo $(LOCALBIN)/downloadIstio https://istio.io/downloadIstio
	chmod +x $(LOCALBIN)/downloadIstio
	ISTIO_VERSION=$(ISTIO_VERSION) $(LOCALBIN)/downloadIstio
	rm -rf $(LOCALBIN)/istio-$(ISTIO_VERSION)
	mv istio-$(ISTIO_VERSION) $(LOCALBIN)
	$(LOCALBIN)/istio-$(ISTIO_VERSION)/bin/istioctl install --set profile=demo -y --set meshConfig.defaultConfig.tracing.zipkin.address=instance-collector.istio-system.svc.cluster.local:9411 --set "components.egressGateways[0].name=istio-egressgateway" --set "components.egressGateways[0].enabled=true"

.PHONY: kiali-operator
kiali-operator: ## Deploy the Kiali operator
	helm repo add kiali https://kiali.org/helm-charts
	helm install --namespace kiali-operator --create-namespace kiali-operator kiali/kiali-operator

################## Application management #######################################################################################
.PHONY: apps
apps:  ## Build and push the demo applications images
	cd apps && docker build -t $(APP_IMG) app
	docker push $(APP_IMG)
	cd apps && docker build -t $(APP2_IMG) app2
	docker push $(APP2_IMG)
	cd apps && docker build -t $(APP3_IMG) app3
	docker push $(APP3_IMG)

.PHONY: deploy-apps
deploy-apps:  ## Deploy the demo applications in the local cluster
	kubectl apply -f apps/manifest.yaml