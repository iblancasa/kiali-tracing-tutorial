# 01- Infrastructure

After installing the dependencies (operators and other stuff), we are going to deploy the infrastructure for the tutotial. That means: all the tools that we need to use in order to have an observable environment using Service Mesh.

## Deploy the infrastructure

TL;DR: run `make infra`.

### Istio

First, we will deploy the service mesh.

[Istio](https://istio.io/) is an open-source service mesh that provides a way to control how microservices share data with one another. It offers a range of features designed to facilitate the management of microservices, including traffic management, security, observability, and policy enforcement.

You can install it with `make istio`.

To verify that Istio was deployed properly, check the pod status:
```sh
$ kubectl get pods -n istio-system                 
NAME                      READY   STATUS    RESTARTS   AGE
istiod-54dcd8b99f-nhcz8   1/1     Running   0          3m39s
```

### Prometheus

[Prometheus](https://prometheus.io/) is an open source monitoring system and time series database. You can use Prometheus with Istio to record metrics that track the health of Istio and of applications within the service mesh. 

Istio allow the installation of addons for tools that are commonly used to complete its features. To deploy Prometheus, we will use the Prometheus addon for Istio:

```sh
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/addons/prometheus.yaml
serviceaccount/prometheus created
configmap/prometheus created
clusterrole.rbac.authorization.k8s.io/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created
service/prometheus created
deployment.apps/prometheus created
```

### Jaeger

For this tutorial we will deploy a Jaeger instance that will store all the traces in memory. This deployment mode is called "all in one" and is good for testing or demo purposes.
```sh
$ kubectl apply -f infra/jaeger.yaml
jaeger.jaegertracing.io/jaeger created
```

To verify the status of our Jaeger instance, we can run the following command:
```sh
$ kubectl get jaeger -n istio-system
NAME     STATUS    VERSION   STRATEGY   STORAGE   AGE
jaeger   Running   1.57.0    allinone   memory    91m
```

The Jaeger operator will have create an Ingress to the Jaeger instance in your cluster. You should be able to acces Jaeger UI via [http://localhost/](http://localhost).

![Jaeger UI](img/00-jaeger.png)

If you refresh the webpage (`F5`) the `Service` dropdown will be populated by `jaeger-all-in-one`. Jaeger itself is instrumented for traces. Each time you query Jaeger or access the UI, new traces will be generated.

## Kiali

> [!WARNING]  
> Note we're not using the [Kiali addon](https://istio.io/latest/docs/ops/integrations/kiali/) for Istio because tracing is disabled in this integration. You can deploy your Kiali instance with this command:

```sh
$ kubectl apply -f infra/kiali.yaml
kiali.kiali.io/kiali created
```

We can verify Kiali is ready with this command:
```sh
$ kubectl get deployment -n istio-system kiali
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
kiali   1/1     1            1           98m
```

To acces the Kiali UI, you need to forward the traffic to the `20001` port:
```
$ kubectl port-forward svc/kiali 20001 -n istio-system
```

And access [http://localhost:20001/](http://localhost:20001/).

![Kiali UI](img/00-kiali.png)
