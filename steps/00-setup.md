# Setup

This tutorial was created to be run in a Linux machine. Developed and tested in `Fedora release 39 (Thirty Nine)`.

A `Makefile` is provided to help attendees to run the different commands easily. You can check what commands are available via `make help`.

> [!TIP]
> Try to run these steps before the tutorial to ensure you are ready to go when it starts!


## Required tools
To follow the tutorial properly, you need to install some tools in your system.

### kubectl

Most of the commands to execute during this tutorial require `kubectl`. You can find how to install it [in the official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux).

### helm
`helm` is a tool to help operators to deploy Kubernetes applications easily. Some of the tools used in this tutorial use `helm`. You can know more in the [official Helm website](https://helm.sh/).

### kind

For this tutorial, you will need acces to a Kubernetes cluster. We recommend to use `kind` to provision one locally in your machine. You can find instructions about how to install kind [in the official documentation website](https://kind.sigs.k8s.io/docs/user/quick-start/).

## Setting up the environment
First, we need to create our Kubernetes cluster. You can just run `make start-kind`.

```sh
$ make start-cluster          
kind create cluster --name=workshop --config=kind.yaml
Creating cluster "workshop" ...
 ✓ Ensuring node image (kindest/node:v1.29.0) 🖼 
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-workshop"
You can now use your cluster with:

kubectl cluster-info --context kind-workshop

Thanks for using kind! 😊
```

Kind automatically sets the kube context to the created workshop cluster. We can easily check this by getting information about our nodes. We can verify if the cluster was created properly checking the nodes:

```sh
$ kubectl get nodes

NAME                     STATUS   ROLES           AGE   VERSION
workshop-control-plane   Ready    control-plane   55s   v1.29.0
```

You can remove the cluster using `make clean`.

## Deploy dependencies

TL;DR: run `make dependencies`.

### cert-manager
[cert-manager](https://cert-manager.io/docs/) is used by OpenTelemetry operator to provision TLS certificates for admission webhooks.

You can install it with `make cert-manager`. The installation will verify itself.

### OpenTelemetry Operator for Kubernetes
The [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) will be used to deploy `OpenTelemetryCollector` and `Instrumentation` instances.

You can install it with `make opentelemetry-operator`.

To verify the OpenTelemetry Operator was deployed properly, check the pod status:
```sh
$ kubectl get pods -n opentelemetry-operator-system
NAME                                                         READY   STATUS    RESTARTS   AGE
opentelemetry-operator-controller-manager-84fcb9457d-t8mhk   2/2     Running   0          20m
```

## Grafana Tempo Operator for Kubernetes.
[Grafana Tempo](https://grafana.com/oss/tempo/) is an open-source, high-scale, distributed tracing backend developed by Grafana Labs. It is designed to handle and store massive volumes of trace data with minimal operational overhead, focusing on simplicity and scalability. Tempo integrates seamlessly with the Grafana ecosystem, allowing users to visualize and analyze traces alongside metrics and logs for comprehensive observability. It supports various tracing protocols, including Jaeger, Zipkin, and OpenTelemetry, enabling the collection of trace data from diverse sources. By providing a unified view of trace data within Grafana dashboards, Tempo helps developers and SREs diagnose and troubleshoot performance issues, track request flows, and understand system dependencies.

The [Grafana Tempo Operator](https://github.com/grafana/tempo-operator) will be used to deploy `TempoStack` instances.

You can install it with `make tempo-operator`.

To verify the Tempo Operator was deployed properly, check the pod status:
```sh
$ kubectl get pods -n tempo-operator-system        
NAME                                         READY   STATUS    RESTARTS   AGE
tempo-operator-controller-557cc7d64b-hclpm   2/2     Running   0          18m
```

## Istio
[Istio](https://istio.io/) is an open-source service mesh that provides a way to control how microservices share data with one another. It offers a range of features designed to facilitate the management of microservices, including traffic management, security, observability, and policy enforcement.

You can install it with `make istio`.

To verify that Istio was deployed properly, check the pod status:
```sh
$ kubectl get pods -n istio-system                 
NAME                      READY   STATUS    RESTARTS   AGE
istiod-54dcd8b99f-nhcz8   1/1     Running   0          3m39s
```

## Kiali operator
[Kiali](https://kiali.io/) is an open-source observability console for Istio service mesh, providing a visual interface to manage and monitor microservices within the mesh. It offers detailed insights into the structure, health, and performance of the microservices, allowing users to visualize service interactions, traffic flow, and dependencies. Kiali integrates with other observability tools like Jaeger for tracing and Prometheus for metrics, enabling comprehensive monitoring and debugging capabilities. It also provides features for validating Istio configurations, identifying potential issues, and facilitating the efficient operation and troubleshooting of microservices in a service mesh environment. We will use the Kiali operator to deploy a Kiali instance in our cluster.

You can install it with `make kiali-operator`.

To verify the deployment, check the pod status:
```sh
$ kubectl get pods -n kiali-operator 
NAME                              READY   STATUS    RESTARTS   AGE
kiali-operator-5dd7c58f5d-7265x   1/1     Running   0          8m20s
```

## Prometheus Operator
[Prometheus]((https://prometheus.io/)) is an open-source systems monitoring and alerting toolkit designed for reliability and scalability, particularly well-suited for monitoring dynamic cloud environments and microservices architectures. It collects and stores time-series data, offering powerful querying capabilities via its PromQL language. Prometheus scrapes metrics from instrumented applications and services, allowing detailed and customizable monitoring. It features a multi-dimensional data model, flexible querying, and alerting through a dedicated Alertmanager, making it a cornerstone for observability in modern infrastructure. Prometheus integrates seamlessly with various systems and provides extensive support for visualization tools like Grafana, enabling comprehensive and insightful monitoring dashboards. The operator will provision a Prometheus instance that will be used by the Kiali instance.

You can install it with `make prometheus-operator`.

To verify the Prometheus operator was deployed properly, check the pod:
```sh
$ kubectl get pods  
NAME                                   READY   STATUS    RESTARTS   AGE
prometheus-operator-69cbc6f76c-9jbdt   1/1     Running   0          15s
```