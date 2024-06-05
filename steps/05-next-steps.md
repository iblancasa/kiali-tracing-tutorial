# 05 - Next steps

After you have your environment up and running, there are several stuff you can check:
- Metamonitoring. For instance, you [can monitor your OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector/blob/main/docs/monitoring.md)
- The [span metrics connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/README.md): Aggregates Request, Error and Duration (R.E.D) OpenTelemetry metrics from span data.
- The [Grafana Tempo operator](https://github.com/grafana/tempo-operator) to deploy Grafana Tempo instances.
- The [Istio documentation](https://istio.io/latest/docs/) to check other interesting features.
- The [resource detection processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourcedetectionprocessor) to detect resource information from the host
- The [k8sattributes processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/k8sattributesprocessor) to set resource attributes with k8s metadata.
- The [batch processor](https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/batchprocessor/README.md) to place telemetry data in batches.