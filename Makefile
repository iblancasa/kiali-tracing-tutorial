# Observe and troubleshoot applications with Kiali and distributed tracing.
#
#   make prepare     everything heavy: cluster, operators, Istio, Prometheus,
#                    Grafana, Jaeger, Kiali, demo images. Run it before the tutorial.
#   make help        list targets
#
# The tutorial itself is a website: https://iblancasa.github.io/kiali-tracing-tutorial/
SHELL := /bin/bash
.DEFAULT_GOAL := help

LOCALBIN ?= $(shell pwd)/bin
CLUSTER  ?= kiali-tracing
KUBECTL  ?= kubectl --context kind-$(CLUSTER)
HELM     ?= helm --kube-context kind-$(CLUSTER)
# How long to wait for each rollout. Most of it is image pulls.
TIMEOUT  ?= 600s

# Versions
# kind is downloaded into bin/, because the Kubernetes 1.37 node image needs
# kind >= 0.33 and an older kind in the PATH fails at "Starting control-plane".
KIND_VERSION                   ?= 0.33.0
KIND_BIN                       := $(LOCALBIN)/kind-$(KIND_VERSION)
KIND                           ?= $(KIND_BIN)
CERTMANAGER_VERSION            ?= 1.21.3
OPENTELEMETRY_OPERATOR_VERSION ?= 0.164.0
KIALI_VERSION                  ?= 2.35.0
ISTIO_VERSION                  ?= 1.32.0
ISTIO_ADDONS                   ?= https://raw.githubusercontent.com/istio/istio/$(ISTIO_VERSION)/samples/addons
ISTIOCTL                       ?= $(LOCALBIN)/istioctl-$(ISTIO_VERSION)

# The demo application, Mesh Pizza. One image for every service, built
# locally and loaded into kind. No registry needed.
APP_IMAGE ?= kiali-tracing-tutorial/mesh-pizza:latest
PORTS     := 8080 20001 16686 3000 9090
APP_URL   ?= http://localhost:8080

.PHONY: help
help: ## Show this help
	@printf "Kiali and distributed tracing tutorial\n\nUsage:\n"
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

################## Everything at once ###########################################################################################
.PHONY: prepare
prepare: check start-cluster dependencies infra build load urls ## Cluster, operators, infrastructure and demo images. Run before the tutorial

.PHONY: check
check: $(KIND_BIN) ## Verify the tools and the host ports
	@CLUSTER=$(CLUSTER) KIND=$(KIND) ./scripts/check-tools.sh $(PORTS)

################## Cluster management ###########################################################################################
.PHONY: start-cluster
$(KIND_BIN):
	@mkdir -p $(LOCALBIN)
	@os=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	arch=$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
	echo "downloading kind $(KIND_VERSION) ($$os-$$arch)"; \
	curl -fsSL -o $(KIND_BIN).tmp https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-$$os-$$arch
	@chmod +x $(KIND_BIN).tmp && mv $(KIND_BIN).tmp $(KIND_BIN)

start-cluster: $(KIND_BIN) ## Start the kind cluster
	@if $(KIND) get clusters 2>/dev/null | grep -qx $(CLUSTER); then \
		echo "kind cluster $(CLUSTER) already exists"; \
	else \
		$(KIND) create cluster --name=$(CLUSTER) --config=kind.yaml; \
	fi

.PHONY: clean
clean: $(KIND_BIN) ## Delete the cluster and the downloaded tools
	$(KIND) delete cluster --name=$(CLUSTER)
	rm -rf $(LOCALBIN)

################## Install dependencies #########################################################################################
.PHONY: dependencies
dependencies: cert-manager opentelemetry-operator kiali-operator ## Deploy cert-manager and the operators

.PHONY: cert-manager
cert-manager: ## Deploy cert-manager (the OpenTelemetry operator needs it for its webhooks)
	$(KUBECTL) apply -f https://github.com/cert-manager/cert-manager/releases/download/v$(CERTMANAGER_VERSION)/cert-manager.yaml
	$(KUBECTL) -n cert-manager rollout status deployment/cert-manager --timeout=$(TIMEOUT)
	$(KUBECTL) -n cert-manager rollout status deployment/cert-manager-cainjector --timeout=$(TIMEOUT)
	$(KUBECTL) -n cert-manager rollout status deployment/cert-manager-webhook --timeout=$(TIMEOUT)

.PHONY: opentelemetry-operator
opentelemetry-operator: ## Deploy the OpenTelemetry operator
	@# The cert-manager webhook can take a few seconds to serve after its rollout: retry.
	@for i in 1 2 3 4 5 6; do \
		$(KUBECTL) apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v$(OPENTELEMETRY_OPERATOR_VERSION)/opentelemetry-operator.yaml && break; \
		echo "cert-manager webhook not ready yet, retrying in 10s"; sleep 10; \
	done
	$(KUBECTL) -n opentelemetry-operator-system rollout status deployment/opentelemetry-operator-controller-manager --timeout=$(TIMEOUT)

.PHONY: kiali-operator
kiali-operator: ## Deploy the Kiali operator
	$(HELM) upgrade --install kiali-operator kiali-operator --repo https://kiali.org/helm-charts \
		--version $(KIALI_VERSION) --namespace kiali-operator --create-namespace --wait --timeout 15m

################## Infrastructure management ####################################################################################
.PHONY: infra
infra: istio prometheus grafana jaeger otelcol kiali ## Deploy Istio, Prometheus, Grafana, Jaeger, the Collector and Kiali

$(ISTIOCTL):
	@mkdir -p $(LOCALBIN)
	@os=$$(uname -s | sed 's/Darwin/osx/;s/Linux/linux/'); \
	arch=$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
	echo "downloading istioctl $(ISTIO_VERSION) ($$os-$$arch)"; \
	curl -fsSL https://github.com/istio/istio/releases/download/$(ISTIO_VERSION)/istioctl-$(ISTIO_VERSION)-$$os-$$arch.tar.gz | tar xz -C $(LOCALBIN) istioctl
	@mv $(LOCALBIN)/istioctl $(ISTIOCTL)

.PHONY: istio
istio: $(ISTIOCTL) ## Deploy Istio with tracing sent to the OpenTelemetry Collector
	$(ISTIOCTL) install --context kind-$(CLUSTER) -y -f infra/istio.yaml
	$(KUBECTL) apply -f infra/telemetry.yaml

.PHONY: prometheus
prometheus: ## Deploy Prometheus (Istio addon)
	$(KUBECTL) apply -f $(ISTIO_ADDONS)/prometheus.yaml
	$(KUBECTL) apply -f infra/nodeports.yaml
	$(KUBECTL) -n istio-system rollout status deployment/prometheus --timeout=$(TIMEOUT)

.PHONY: grafana
grafana: ## Deploy Grafana with the Istio dashboards (Istio addon)
	$(KUBECTL) apply -f $(ISTIO_ADDONS)/grafana.yaml
	$(KUBECTL) apply -f infra/nodeports.yaml
	$(KUBECTL) -n istio-system rollout status deployment/grafana --timeout=$(TIMEOUT)

.PHONY: otelcol
otelcol: ## Deploy the OpenTelemetry Collector
	$(KUBECTL) apply -f infra/otelcol.yaml
	@until $(KUBECTL) -n istio-system get deployment/otel-collector >/dev/null 2>&1; do sleep 2; done
	$(KUBECTL) -n istio-system rollout status deployment/otel-collector --timeout=$(TIMEOUT)

.PHONY: jaeger
jaeger: ## Deploy Jaeger
	$(KUBECTL) apply -f infra/jaeger.yaml
	$(KUBECTL) -n istio-system rollout status deployment/jaeger --timeout=$(TIMEOUT)

.PHONY: kiali
kiali: ## Deploy Kiali
	$(KUBECTL) apply -f infra/kiali.yaml
	@echo "waiting for the Kiali operator to create the deployment"
	@until $(KUBECTL) -n istio-system get deployment/kiali >/dev/null 2>&1; do sleep 5; done
	$(KUBECTL) -n istio-system rollout status deployment/kiali --timeout=$(TIMEOUT)

################## Application management #######################################################################################
.PHONY: build
build: ## Build the image of the demo application
	docker build -t $(APP_IMAGE) apps

.PHONY: load
load: ## Load the image of the demo application into the kind cluster
	$(KIND) load docker-image --name $(CLUSTER) $(APP_IMAGE)

.PHONY: ensure-image
ensure-image: $(KIND_BIN)
	@if ! docker exec $(CLUSTER)-control-plane crictl inspecti $(APP_IMAGE) >/dev/null 2>&1; then \
		echo "image $(APP_IMAGE) is not in the cluster: building and loading it"; \
		docker image inspect $(APP_IMAGE) >/dev/null 2>&1 || $(MAKE) --no-print-directory build; \
		$(MAKE) --no-print-directory load; \
	fi

.PHONY: deploy-apps
deploy-apps: ensure-image ## Step 2: deploy Mesh Pizza and its load generator
	$(KUBECTL) apply -f apps/manifest.yaml
	$(KUBECTL) -n demo rollout status deployment --timeout=$(TIMEOUT)

.PHONY: restart-apps
restart-apps: ## Restart every deployment of the demo
	$(KUBECTL) -n demo rollout restart deployment
	$(KUBECTL) -n demo rollout status deployment --timeout=$(TIMEOUT)

.PHONY: propagate
propagate: ## Step 3: the applications forward the trace headers themselves
	$(KUBECTL) -n demo set env deployment -l 'app!=redis' PROPAGATE_TRACE_HEADERS=true
	$(KUBECTL) -n demo rollout status deployment --timeout=$(TIMEOUT)

.PHONY: unpropagate
unpropagate: ## Stop forwarding the trace headers
	$(KUBECTL) -n demo set env deployment -l 'app!=redis' PROPAGATE_TRACE_HEADERS-
	$(KUBECTL) -n demo rollout status deployment --timeout=$(TIMEOUT)

.PHONY: instrument
instrument: ## Step 4: create the Instrumentation and annotate the deployments
	$(KUBECTL) apply -f infra/instrumentation.yaml
	$(KUBECTL) -n demo patch $$($(KUBECTL) -n demo get deployment -l 'app!=redis' -o name) --type merge \
		-p '{"spec":{"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/inject-python":"true","traffic.sidecar.istio.io/excludeOutboundPorts":"4318"}}}}}'
	$(KUBECTL) -n demo rollout status deployment --timeout=$(TIMEOUT)

.PHONY: uninstrument
uninstrument: ## Remove the auto-instrumentation again
	$(KUBECTL) -n demo patch $$($(KUBECTL) -n demo get deployment -l 'app!=redis' -o name) --type json \
		-p '[{"op":"remove","path":"/spec/template/metadata/annotations/instrumentation.opentelemetry.io~1inject-python"},{"op":"remove","path":"/spec/template/metadata/annotations/traffic.sidecar.istio.io~1excludeOutboundPorts"}]'
	$(KUBECTL) -n demo delete -f infra/instrumentation.yaml --ignore-not-found
	$(KUBECTL) -n demo rollout status deployment --timeout=$(TIMEOUT)

.PHONY: reset
reset: ## Back to the start of step 2: no header forwarding, no instrumentation, empty Jaeger
	-$(MAKE) uninstrument
	-$(MAKE) unpropagate
	$(KUBECTL) -n istio-system rollout restart deployment/jaeger
	$(KUBECTL) -n istio-system rollout status deployment/jaeger --timeout=$(TIMEOUT)

################## Traffic ######################################################################################################
.PHONY: traffic-on
traffic-on: ## Start the load generator (3 requests per second)
	$(KUBECTL) -n loadgen scale deployment/loadgen --replicas=1

.PHONY: traffic-off
traffic-off: ## Stop the load generator
	$(KUBECTL) -n loadgen scale deployment/loadgen --replicas=0

.PHONY: traffic-logs
traffic-logs: ## Watch the load generator
	$(KUBECTL) -n loadgen logs deployment/loadgen -f --tail=20

.PHONY: order
order: ## Order one pizza by hand
	@curl -s -w '\n-> HTTP %{http_code} in %{time_total}s\n' -X POST $(APP_URL)/api/orders \
		-H 'content-type: application/json' -d '{"pizza":"margherita","qty":1}'

################## Looking at things ############################################################################################
.PHONY: status
status: ## Pods of the tutorial
	$(KUBECTL) get pods -n istio-system
	@echo
	@$(KUBECTL) get pods -n demo 2>/dev/null || true

.PHONY: urls
urls: ## Print the URLs
	@echo
	@echo "  Mesh Pizza   http://localhost:8080      (after step 2)"
	@echo "  Kiali        http://localhost:20001"
	@echo "  Jaeger       http://localhost:16686"
	@echo "  Grafana      http://localhost:3000"
	@echo "  Prometheus   http://localhost:9090"
	@echo

.PHONY: port-forward
port-forward: ## Fallback if the host ports are taken
	$(KUBECTL) -n istio-system port-forward svc/istio-ingressgateway 8080:80 & \
	$(KUBECTL) -n istio-system port-forward svc/kiali 20001:20001 & \
	$(KUBECTL) -n istio-system port-forward svc/jaeger 16686:16686 & \
	$(KUBECTL) -n istio-system port-forward svc/grafana 3000:3000 & \
	$(KUBECTL) -n istio-system port-forward svc/prometheus 9090:9090 & wait

################## Website ######################################################################################################
.PHONY: site
site: ## Run the tutorial website locally (http://localhost:4321/kiali-tracing-tutorial/)
	cd site && npm install && npm run dev

.PHONY: site-build
site-build: ## Build the static website into site/dist/
	cd site && npm install && npm run build

.PHONY: casts
casts: ## Re-record the terminal transcripts of the website (needs asciinema and a fresh `make prepare`)
	./scripts/record-casts.sh
