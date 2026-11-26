# Observe and troubleshoot applications with Kiali and distributed tracing

Hands-on tutorial about Kiali, Istio and distributed tracing. Everything runs
on your laptop in a [kind](https://kind.sigs.k8s.io/) cluster.

**The tutorial itself lives on the website:**
https://iblancasa.github.io/kiali-tracing-tutorial/ (source in [`site/`](site/)).

Presented at:
* [DevConf 2024](https://pretalx.com/devconf-cz-2024/talk/A8DAGH/)

## What is inside

```
loadgen -> ingress gateway -> frontend -+-> menu -+-> pricing -> promotions
                                        |         '-> reviews (v1, v2) -> ratings
                                        |
                                        '-> orders -+-> inventory -> redis
                                                    +-> payments -> fraud
                                                    +-> kitchen -> inventory
                                                    +-> delivery -> maps
                                                    '-> notifications

Envoy proxies and applications --OTLP--> OpenTelemetry Collector --OTLP--> Jaeger
Envoy proxies <--scrape-- Prometheus <-- Kiali, Grafana
```

| Tool | Version | Open it at |
|---|---|---|
| [Istio](https://istio.io/) | 1.32 | |
| [Kiali](https://kiali.io/) | 2.35 | http://localhost:20001 |
| [Jaeger](https://www.jaegertracing.io/) | 2.23 | http://localhost:16686 |
| [Grafana](https://grafana.com/oss/grafana/) | Istio addon | http://localhost:3000 |
| [Prometheus](https://prometheus.io/) | Istio addon | http://localhost:9090 |
| [OpenTelemetry operator](https://github.com/open-telemetry/opentelemetry-operator) | 0.164 | |
| Mesh Pizza, the demo application | | http://localhost:8080 |

## Quick start

Needs Docker, `kubectl`, `helm`, `make` and `curl`. `kind` and `istioctl` are
downloaded into `bin/`.

```bash
make prepare      # cluster, operators, Istio, Prometheus, Grafana, Jaeger, Kiali, demo image
make deploy-apps  # step 2
make propagate    # step 3
make instrument   # step 4
make clean        # delete everything
```

`make help` lists every target. The website explains what each one does and
what to look at afterwards.

## Layout

```
Makefile              every command of the tutorial
kind.yaml             the cluster, with the five host ports
infra/                Istio, Telemetry, OpenTelemetry Collector, Jaeger, Kiali, Instrumentation
apps/                 Mesh Pizza: one image, one Python module per service, one manifest
scripts/              tool check, terminal recording for the website
site/                 the website (Astro Starlight)
.github/workflows/    builds site/ and publishes it to GitHub Pages
```

## Website

```bash
make site         # dev server on http://localhost:4321/kiali-tracing-tutorial/
make site-build   # static build into site/dist/
```

## License

Apache 2.0.
