---
title: Commands
description: Every make target of the tutorial, grouped by when you need it, with the ports and names worth remembering.
---

Run `make help` for the same list. Every target is a few lines of
`kubectl`, `helm` or `istioctl` in the
[Makefile](https://github.com/iblancasa/kiali-tracing-tutorial/blob/main/Makefile).

## Setup

| Command | What it does |
|---------|--------------|
| `make check` | Download kind into `bin/`, verify docker, kubectl, helm and that ports 8080, 20001, 16686, 3000 and 9090 are free |
| `make prepare` | Everything below, in order: `check`, `start-cluster`, `dependencies`, `infra`, `build`, `load` |
| `make start-cluster` | Create the kind cluster `kiali-tracing` |
| `make dependencies` | `cert-manager`, `opentelemetry-operator`, `kiali-operator` |
| `make infra` | `istio`, `prometheus`, `grafana`, `otelcol`, `jaeger`, `kiali` |
| `make build`, `make load` | Build the Mesh Pizza image and load it into the cluster |
| `make urls` | Print the five URLs |
| `make status` | Pods in `istio-system` and `demo` |
| `make port-forward` | Fallback if a host port is taken |
| `make clean` | Delete the cluster and `bin/` |

## Tutorial steps

| Command | Step | What it does |
|---------|------|--------------|
| `make deploy-apps` | 2 | Apply `apps/manifest.yaml`, wait for the rollout |
| `make propagate` | 3 | `PROPAGATE_TRACE_HEADERS=true` on every deployment of the shop |
| `make unpropagate` | | Remove the variable again |
| `make instrument` | 4 | Create the `Instrumentation`, annotate the deployments |
| `make uninstrument` | | Remove the annotation and the `Instrumentation` |
| `make reset` | | Start of step 2 again: no forwarding, no instrumentation, Jaeger emptied |
| `make restart-apps` | | Restart every deployment of the shop |

## Traffic

| Command | What it does |
|---------|--------------|
| `make traffic-logs` | Watch the load generator: `method path -> status in ms` |
| `make traffic-off` | Scale the load generator to zero |
| `make traffic-on` | Scale it back to one (3 requests per second) |
| `make order` | Order one pizza with `curl` |

## Website

| Command | What it does |
|---------|--------------|
| `make site` | Run this website locally (Astro dev server) |
| `make site-build` | Build the static site into `site/dist/` |
| `make casts` | Re-record the terminal transcripts against a cluster fresh from `make prepare` |

## Ports and names

| Thing | Value |
|-------|-------|
| kind cluster | `kiali-tracing` (`kubectl --context kind-kiali-tracing`) |
| Mesh Pizza | http://localhost:8080 (Istio ingress gateway, NodePort 30080) |
| Kiali | http://localhost:20001 (NodePort 30001) |
| Jaeger UI and API | http://localhost:16686 (NodePort 30686) |
| Grafana | http://localhost:3000 (NodePort 30000) |
| Prometheus | http://localhost:9090 (NodePort 30090) |
| OTLP inside the cluster | `otel-collector.istio-system.svc.cluster.local:4317` (gRPC), `:4318` (HTTP) |
| Jaeger inside the cluster | `jaeger.istio-system.svc.cluster.local:4317` (OTLP), `:16685` (gRPC query) |
| Namespaces | `demo` (the shop, in the mesh), `loadgen` (outside the mesh), `istio-system` (everything else) |
| Public API of the shop | `GET /`, `GET /api/menu`, `POST /api/orders` with `{"pizza":"margherita","qty":1}` |
| Pizzas | `margherita`, `diavola`, `quattro-formaggi`, `hawaiian` |

## Versions

Set at the top of the Makefile. Override on the command line, for example
`make istio ISTIO_VERSION=1.32.1`.

| Variable | Value |
|----------|-------|
| `ISTIO_VERSION` | 1.32.0 |
| `KIALI_VERSION` | 2.35.0 |
| `OPENTELEMETRY_OPERATOR_VERSION` | 0.164.0 |
| `CERTMANAGER_VERSION` | 1.21.3 |
| Jaeger | 2.23.0, in `infra/jaeger.yaml` |
| Kubernetes | 1.37.0, in `kind.yaml` |
| Prometheus, Grafana | whatever the Istio addons of `ISTIO_VERSION` ship |
