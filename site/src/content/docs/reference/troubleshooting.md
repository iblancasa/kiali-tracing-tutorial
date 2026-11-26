---
title: Troubleshooting
description: Symptoms seen while building this tutorial and the fix for each.
---

| Symptom | Fix |
|---------|-----|
| `kind create cluster` fails with a kubeadm error, or hangs at "Starting control-plane" | A small Docker VM, or an old kind if you ran `kind` yourself or set `KIND=`. The node image is Kubernetes 1.37 and needs kind >= 0.33, which `make` downloads as `bin/kind-0.33.0`. Give Docker 8 GB: Docker Desktop, Settings > Resources. Colima: `colima start --cpu 4 --memory 8`. |
| `address already in use` on 8080, 20001, 16686, 3000 or 9090 | Stop whatever uses the port and create the cluster again, or keep the cluster and run `make port-forward` in a second terminal. |
| `make prepare` stops with `timed out waiting for the condition` or `context deadline exceeded` | A slow image pull. Run `make prepare` again, it continues where it stopped. The Kiali images are the big ones (200 MB each). `make prepare TIMEOUT=1200s` waits longer. |
| `make opentelemetry-operator` prints `failed calling webhook "webhook.cert-manager.io"` | The cert-manager webhook was not serving yet. The target retries by itself, six times. |
| Pods in `demo` show `ErrImageNeverPull` or `ImagePullBackOff` for `kiali-tracing-tutorial/mesh-pizza` | The image is not in the cluster: `make build load`. |
| Pods in `demo` have one container instead of two | They started before Istio was ready, or the namespace lost its `istio-injection=enabled` label. `make restart-apps`. |
| [localhost:8080](http://localhost:8080) refuses the connection | The demo is not deployed (`make deploy-apps`), or the ingress gateway is not running: `kubectl -n istio-system get pods`. |
| Kiali's graph is empty | Check the namespace selector (`demo`) and the time range (last 1m by default). Then `make traffic-logs`: if the load generator is not running, `make traffic-on`. |
| Kiali's graph has grey edges and no numbers | No traffic in the selected time range. Same as above. |
| Kiali shows no traces, the tab says tracing is not available | Jaeger restarted and Kiali lost its gRPC connection: `kubectl -n istio-system rollout restart deployment/kiali`. |
| Kiali's log says `jaeger version check failed` | Harmless. Kiali probes an HTTP port this Jaeger does not serve. Traces go over gRPC on 16685. |
| Jaeger lists no services after `make deploy-apps` | Wait 30 seconds and reload the page, the Service dropdown is loaded once. Then check the pipeline, below. |
| After `make propagate` some traces still have 3 spans | Requests that were in flight during the rollout. Look at traces of the last minute only. |
| After `make instrument` the application spans are next to the proxy spans, not under them | The applications and the proxies use different propagation formats. `infra/instrumentation.yaml` must list `tracecontext` and not `b3multi` when Istio uses the OpenTelemetry provider. |
| After `make instrument` the application logs say `Failed to export logs batch code: 404` | The `Instrumentation` lost its `OTEL_LOGS_EXPORTER=none` and `OTEL_METRICS_EXPORTER=none` settings. The Collector only has a traces pipeline. |
| Jaeger shows one-span traces called `otel-collector.istio-system.svc.cluster.local:4318/*` | The sidecar is tracing the SDK's own export requests. `make instrument` adds `traffic.sidecar.istio.io/excludeOutboundPorts: "4318"` to avoid it. |
| Everything was fine and now Jaeger is empty | Jaeger restarted. Traces live in memory. Wait a minute for new ones. |
| `kubectl top pods` fails | kind has no metrics-server. Not needed here. |
| Windows | WSL2 + Docker Desktop WSL integration, run everything inside WSL. Native is untested. |

## Verify the pipeline by hand

```bash
# do the proxies know where to send spans?
kubectl -n istio-system get telemetry mesh-default -o yaml
kubectl -n istio-system get configmap istio -o jsonpath='{.data.mesh}'

# is the Collector receiving and forwarding? Any export error shows here
kubectl -n istio-system logs deployment/otel-collector --tail=20

# does Jaeger have data?
curl -s localhost:16686/api/v3/services
scripts/traces.py

# does Prometheus have the mesh metrics?
curl -s localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(istio_requests_total[1m]))'

# is the Instrumentation applied to a pod? (step 4)
kubectl -n demo get pod -l app=orders -o jsonpath='{.items[0].spec.initContainers[*].name}'
```

## Start over

```bash
make reset                    # start of step 2 again (keeps the cluster and the demo)
kubectl delete -f apps/manifest.yaml && make deploy-apps
make clean && make prepare    # everything
```
