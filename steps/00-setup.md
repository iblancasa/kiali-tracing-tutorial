# Setup

This tutorial was created to be run in a Linux machine. Developed and tested in `Fedora release 39 (Thirty Nine)`.

A `Makefile` is provided to help attendees to run the different commands easily. You can check what commands are available via `make help`.

> [!TIP]
> Try to run these steps before the tutorial to ensure you are ready to go when it starts!


## Required tools
To follow the tutorial properly, you need to install some tools in your system.

### kubectl

Most of the commands to execute during this tutorial require `kubectl`. You can find how to install it [in the official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux).

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

You can install it with `make cert-manager`.


### OpenTelemetry Operator for Kubernetes
The [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) will be used to deploy `OpenTelemetryCollector` and `Instrumentation` instances.

You can install it with `make opentelemetry-operator`.

## Grafana Tempo Operator for Kubernetes.

The [Grafana Tempo Operator](https://github.com/grafana/tempo-operator) will be used to deploy `TempoStack` instances.

You can install it with `make tempo-operator`.