# 00 - Setup

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

### cloud-provider-kind
The cloud-provider-kind project is an extension for KIND (Kubernetes IN Docker) that enables testing Kubernetes features dependent on cloud-provider functionality, particularly LoadBalancer services, in a local KIND cluster. KIND is a tool for running local Kubernetes clusters using Docker container nodes, which is typically used for development and CI purposes. However, KIND lacks support for cloud-provider-dependent features like LoadBalancers, which are essential for simulating production-like environments.

Learn how to install [from the GitHub repository](https://github.com/kubernetes-sigs/cloud-provider-kind).

## Setting up the environment
First, we need to create our Kubernetes cluster. You can just run `make start-kind`. Note that this command will also install the Nginx Ingress controller for kind.

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
kubectl create -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.1/deploy/static/provider/kind/deploy.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
configmap/ingress-nginx-controller created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
service/ingress-nginx-controller-admission created
service/ingress-nginx-controller created
deployment.apps/ingress-nginx-controller created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
serviceaccount/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
```

Kind automatically sets the kube context to the created workshop cluster. We can easily check this by getting information about our nodes. We can verify if the cluster was created properly checking the nodes:

```sh
$ kubectl get nodes
NAME                     STATUS   ROLES           AGE   VERSION
workshop-control-plane   Ready    control-plane   80s   v1.29.0
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

## Jaeger Operator for Kubernetes
[Jaeger](https://www.jaegertracing.io/docs/1.57/operator/) is an open-source, end-to-end distributed tracing system used for monitoring and troubleshooting microservices-based applications. It helps track the flow of requests through various services, providing insights into service latencies, root causes of performance issues, and service dependencies. Developed initially by Uber Technologies and now part of the Cloud Native Computing Foundation (CNCF), Jaeger supports various features such as context propagation, distributed context management, and spans and traces collection. It integrates with a wide range of tools and platforms, facilitating the visualization of request flows and pinpointing issues within complex microservice architectures, ultimately enhancing the observability and reliability of distributed systems​​​​. We will use the Jaeger operator to deploy Jaeger instances.

You can install it with `make jaeger-operator`.

To verify the Tempo Operator was deployed properly, check the pod status:
```sh
$ kubectl get pods -n observability
NAME                              READY   STATUS    RESTARTS   AGE
jaeger-operator-8f4765884-7ntr4   2/2     Running   0          12s
```

## Kiali operator
[Kiali](https://kiali.io/) is an open-source observability console for Istio service mesh, providing a visual interface to manage and monitor microservices within the mesh. It offers detailed insights into the structure, health, and performance of the microservices, allowing users to visualize service interactions, traffic flow, and dependencies. Kiali integrates with other observability tools like Jaeger for tracing and Prometheus for metrics, enabling comprehensive monitoring and debugging capabilities. It also provides features for validating Istio configurations, identifying potential issues, and facilitating the efficient operation and troubleshooting of microservices in a service mesh environment. We will use the Kiali operator to deploy a Kiali instance in our cluster. For this tutorial we will install Kiali using the Kiali operator for Kubernetes.

You can install it with `make kiali-operator`.

To verify the deployment, check the pod status:
```sh
$ kubectl get pods -n kiali-operator 
NAME                              READY   STATUS    RESTARTS   AGE
kiali-operator-5dd7c58f5d-7265x   1/1     Running   0          8m20s
```
