### Workshop:

## Building a multi-platform Kubernetes cluster on bare metal with `kubeadm`

Hi and welcome to this tutorial and demonstration of how to build a bare-metal Kubernetes cluster with kubeadm!

I'm one of the main kubeadm developers and very excited about bare metal as well, 
so I thought showing some of the things you can do with Kubernetes/kubeadm would be a great fit!

### Highligts

* Showcases what you can do on bare-metal, even behind a firewall with no public IP address

What's more, the Kubernetes yaml manifests included in this repository are multi-architecture and works on ARM, both 32- and 64-bit!

My own setup at home consists of this hardware:
 - 2x Up Board, 4 cores @ 1.44 GHz, 2 GB RAM, 1 GbE, 16 GB eMMc, amd64, [Link](http://up-shop.org/up-boards/2-up-board-2gb-16-gb-emmc-memory.html)
 - 2x Odroid C2, 4 cores @ 1.5 GHz, 2 GB RAM, 1 GbE, 16 GB eMMc, arm64, [Link](http://www.hardkernel.com/main/products/prdt_info.php)
 - 3x Raspberry Pi, 4 cores @ 1.2 GHz, 1 GB RAM, 100 MbE, 16 GB SD Card, arm/arm64, [Link](https://www.raspberrypi.org/products/raspberry-pi-3-model-b/)

[Picture](#TODO)

So, no more smalltalk then, let's dive right in!

### Contents

This workshop is divided into these parts:

* Installing kubeadm on all the machines you want in your cluster
* Setting up your Kubernetes master
* Setting up the worker nodes
* Deploying the Pod networking layer
* Deploying the Dashboard and Heapster
* Deploying an Ingress Controller for exposing HTTP services
* Deploying a persistent storage layer on top of Kubernetes with Rook
* Deploying InfluxDB and Grafana for storing and visualizing CPU and memory metrics
* Deploying a sample Wordpress service with a MariaDB backend using `helm`
* Deploying a extension API Server for extending the Kubernetes API
* Deploying the Prometheus Operator for monitoring Services in the cluster

### Installing kubeadm on all the machines you want in your cluster

> WARNING: This workshop uses alpha technologies in order to be on the edge and Kubernetes can't be upgraded.
> This means the features used and demonstrated here might work differently in v1.7 and backwards-compability isn't guaranteed.

**Note:** The first part that describes how to install kubeadm is just copied from the [official kubeadm documentation](https://kubernetes.io/docs/getting-started-guides/kubeadm/)

**Note:** It's expected that you have basic knowledge about how Kubernetes and kubeadm work, because quite advanced concepts are covered in this workshop.

**Note:** This guide has been tested on Ubuntu Xenial and Yakkety, and 

You can install kubeadm easily this way:

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial-unstable main
EOF
apt-get update
apt-get install -y docker.io kubeadm
```

You should do this on all machines you're planning to include in your cluster, and these commands are exactly the same regardless on which architecture you are on.

### Setting up your Kubernetes master

SSH into your master node, and switch to the `root` account of the machine or use `sudo` everywhere below.

As mentioned earlier, experimental features of different kinds will be used in this tutorial to show off the latest and greatest features in Kubernetes.

kubeadm for example, can take options from a configuration file in order to be customized easily.
But the API exposed in v1.6 is _not_ stable, and under heavy development. So this will definitely change (to the better) in time for v1.7.

The configuration file we'll use here looks like this in `kubeadm.yaml`:

```yaml
kind: MasterConfiguration
apiVersion: kubeadm.k8s.io/v1alpha1
networking:
  podSubnet: "10.244.0.0/16"
controllerManagerExtraArgs:
  controllers: "*,-persistentvolume-binder"
  horizontal-pod-autoscaler-use-rest-clients: "true"
  horizontal-pod-autoscaler-sync-period: "10s"
  node-monitor-grace-period: "10s"
apiServerExtraArgs:
  runtime-config: "api/all=true"
  feature-gates: "TaintBasedEvictions=true"
  proxy-client-cert-file: "/etc/kubernetes/pki/front-proxy-client.crt"
  proxy-client-key-file: "/etc/kubernetes/pki/front-proxy-client.key"
selfHosted: true
```

A brief walkthrough what the statements mean:
 - `podSubnet: "10.244.0.0/16"` makes `kube-proxy` aware of which packets are internal and external
 - `controllers: "*,-persistentvolume-binder"` disables the `persistentvolume-binder` controller
   - since the ``persistentvolume-binder`` exec's out to an `rbd` binary and that binary is unavailable in the official controller-manager image
     combined with the fact that this is a `rook`-specific thing, it's better to run the `persistentvolume-binder` controller in a separately
     maintained image which has the `rbd` binary included.
 - `horizontal-pod-autoscaler-use-rest-clients: "true"` tells the controller manager to look for [custom metrics](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/custom-metrics-api.md)
 - `runtime-config: "api/all=true"` enables the `autoscaling/v2alpha1` API
 - `proxy-client-cert-file/proxy-client-key-file` set the cert/key pair for the API Server when it's talking to the built-in aggregated API Server.

You can now go ahead and initialize the master node with this command (assuming you're `root`, append `sudo` if not):

```console
$ KUBE_HYPERKUBE_IMAGE=luxas/hyperkube:v1.6.0-kubeadm-workshop kubeadm init --config kubeadm.yaml
```

In order to control your cluster securely, you need to specify the `KUBECONFIG` variable to `kubectl` knows where to look for the admin credentials.
Here is an example how to do it as a regular user.

```bash
sudo cp /etc/kubernetes/admin.conf $HOME/
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
```

`KUBE_HYPERKUBE_IMAGE` is an alpha feature of kubeadm and will be an option in the config file in future versions of kubeadm.

#### Deploying the Pod networking layer

The networking layer in Kubernetes is extensible, and you may pick the networking solution that fits you the best.
I've tested this with Weave Net, but it should work with any other compliant provider.

Here's how to use Weave Net as the networking provider:

```console
$ kubectl apply -f https://git.io/weave-kube-1.6
```

#### Untainting the master node

In case you only have one node available for testing and want to run normal workloads on the master as well, run this command:

```console
$ kubectl taint nodes --all node-role.kubernetes.io/master-
```

### Setting up the worker nodes

`kubeadm init` above will print out a `kubeadm join` command for you to paste for joining the other nodes in your cluster to the master.

```console
$ kubeadm join --token <token> <master-ip>:<master-port>
```

### Deploying the Dashboard and Heapster

I really like visualizing the cluster resources in the [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) (although I'm mostly a CLI guy).

You can install the dashboard with this command:

```console
$ kubectl apply -f demos/dashboard/dashboard.yaml
serviceaccount "dashboard" created
clusterrolebinding "dashboard-admin" created
deployment "kubernetes-dashboard" created
service "kubernetes-dashboard" created
```

You probably want some monitoring as well, if you install [Heapster](https://github.com/kubernetes/heapster) you can easily keep track of the CPU and
memory usage in your cluster. Those stats will also be shown in the dashboard!

```console
$ kubectl apply -f demos/monitoring/heapster.yaml
serviceaccount "heapster" created
clusterrolebinding "heapster" created
deployment "heapster" created
service "heapster" created
```

You should now see some Services in the `kube-system` namespace:

```console
$ kubectl -n kube-system get svc
TODO
```

After `heapster` is up and running (check with `kubectl -n kube-system get pods`), you should be able to see the 
CPU and memory usage of the nodes in the cluster and for individual Pods:

```console
$ kubectl top nodes
TODO
```

### Deploying an Ingress Controller for exposing HTTP services

Now that you have created the dashboard and heapster Deployments and Services, how can you access them?

One solution might be making your Services of the NodePort type, but that's not a good long-term solution.

Instead, there is the Ingress object in Kubernetes that let's you create rules for how Services in your cluster should be exposed to the world.
Before one can create Ingress rules, you need a Ingress Controller that watches for rules, applies them and forwards requests as specified.

One Ingress Controller provider is [Traefik](traefik.io), and I'm using that one here.

In this demo I go a step further. Normally in order to expose your app you have locally to the internet requires that one of your machines has a public Internet
address. We can workaround this very smoothly in a Kubernetes cluster by letting [Ngrok](ngrok.io) forward requests from a public subdomain of `ngrok.io` to the
Traefik Ingress Controller that's running in our cluster.

Using ngrok here is perfect for hybrid clusters where you have no control over the network you're connected to... you just have internet access.
Also, this method is can be used in nearly any environment and will behave the same. But for production deployments (which we aren't dealing with here),
you should of course expose a real loadbalancer node with a public IP.

```console
$ kubectl apply -f demos/loadbalancing/traefik-common.yaml
clusterrole "traefik-ingress-controller" created
serviceaccount "traefik-ingress-controller" created
clusterrolebinding "traefik-ingress-controller" created
configmap "traefik-cfg" created

$ kubectl apply -f demos/loadbalancing/traefik-ngrok.yaml
deployment "traefik-ingress-controller" created
service "traefik-ingress-controller" created
service "traefik-web" created
configmap "ngrok-cfg" created
deployment "ngrok" created
service "ngrok" created

$ curl -sSL $(kubectl -n kube-system get svc ngrok -o template --template "{{.spec.clusterIP}}")/api/tunnels | jq  ".tunnels[].public_url" | sed 's/"//g;/http:/d'
https://foobarxyz.ngrok.io
```

You can now try to access the ngrok URL that got outputted by the above command. It should look like this:

[Image](#TODO)

However, since we have no Ingress rules, Traefik just returns 404.

Let's change that by creating an Ingress rule!

#### Exposing the Dashboard via the Ingress Controller

We want to expose the dashboard to our newly-created public URL, under the `/dashboard` path.

That's easily achievable using this command:

```console
$ kubectl apply -f demos/dashboard/ingress.yaml
ingress "kubernetes-dashboard" created
```

The Traefik Ingress Controller is set up to require basic auth before one can access the services.

I've set the username to `kubernetes` and the password to `rocks!`. You can obviously change this if you want by editing the `traefik-common.yaml` before deploying
the Ingress Controller.

When you've signed in, you'll see a dashboard like this:

[Image](#TODO)

### Deploying a persistent storage layer on top of Kubernetes with Rook

Stateless services are cool, but deploying stateful applications on your Kubernetes cluster is even more fun.

For that you need somewhere to store persistent data, and that's not easy to achieve on bare metal. [Rook](https://github.com/rook/rook) is a promising project
aiming to solve this by building a Kubernetes integration layer upon the battle-tested Ceph storage solution.

Rook is using `ThirdPartyResources` for knowing how to set up your storage solution, and has an [operator](#TODO) that is listening for these TPRs.

Here is how to create a default Rook cluster by deploying the operator, a controller that will listen for PersistentVolumeClaims that need binding, a Rook Cluster
ThirdPartyResource and finally a StorageClass.

```console
$ kubectl apply -f demos/storage/rook/operator.yaml
clusterrole "rook-operator" created
serviceaccount "rook-operator" created
clusterrolebinding "rook-operator" created
deployment "rook-operator" created

$ kubectl apply -f demos/storage/rook/pvcontroller.yaml
serviceaccount "persistent-volume-binder" created
clusterrolebinding "persistent-volume-binder" created
deployment "pv-controller-manager" created

$ kubectl apply -f demos/storage/rook/cluster.yaml
cluster "my-rook" created

$ export MONS=$(kubectl -n rook get pod mon0 mon1 mon2 -o json|jq ".items[].status.podIP"|tr -d "\""|sed -e 's/$/:6790/'|paste -s -d, -)
$ echo $MONS
10.32.0.17:6790,10.32.0.18:6790,10.32.0.19:6790
$ sed 's#INSERT_HERE#'$MONS'#' demos/storage/rook/storageclass.yaml | kubectl apply -f -
storageclass "rook-block" created

$ # Repeat this step for all namespaces you want to deploy PersistentVolumes with Rook in
$ kubectl get secret rook-rbd-user -oyaml | sed "/resourceVer/d;/uid/d;/self/d;/creat/d;/namespace/d" | kubectl -n kube-system apply -f -
secret "rook-rbd-user" created
```

One limitation with v0.3.0 is that you can't control to which namespaces the rook authentication Secret should be deployed, so if you want to create
`PersistentVolumes` in an other namespace than `default`, run the above `kubectl` command.

### Deploying InfluxDB and Grafana for storing and visualizing CPU and memory metrics

Now that we have got persistent storage in our cluster, we can deploy some stateful services. For example, we can store monitoring data aggregated by Heapster
in an InfluxDB database and visualize that data with a Grafana dashboard.

You must do this if you want to gather CPU/memory data from Heapster for a longer time, by default heapster just saves data from the latest couple of minutes.

```console
$ kubectl apply -f demos/monitoring/influx-grafana.yaml
persistentvolumeclaim "grafana-pv-claim" created
persistentvolumeclaim "influxdb-pv-claim" created
deployment "monitoring-grafana" created
service "monitoring-grafana" created
deployment "monitoring-influxdb" created
service "monitoring-influxdb" created
ingress "monitoring-grafana" created
```

Note that an Ingress rule was created for Grafana automatically. You can access your Grafana instance at the `https://{ngrok url}/grafana` URL.

### Sample API Server

The core API Server is great, but what about if you want to write your own, extended API server that contains more high-level features that build on top of Kubernetes
but still be able to control those high-level features from kubectl?

This is possible, a lot of work has been put into this and this feature will probably be ready in Kubernetes v1.7. If you can't wait, like me, you can test this flow 
out easily already. The reason I'm using my own `hyperkube` image for this demo is two-fold:

1) Since the hyperkube is a manifest list, it will work on multiple platforms smoothly out of the box
2) It contains vanilla v1.6 Kubernetes + [this patch](#TODO) that makes it possible to register extended API Servers smoothly.

First, let's check which API groups are available in v1.6:

```console
$ kubectl api-versions
apiregistration.k8s.io/v1alpha1
apps/v1beta1
authentication.k8s.io/v1
authentication.k8s.io/v1beta1
authorization.k8s.io/v1
authorization.k8s.io/v1beta1
autoscaling/v1
autoscaling/v2alpha1
batch/v1
batch/v2alpha1
certificates.k8s.io/v1beta1
extensions/v1beta1
policy/v1beta1
rbac.authorization.k8s.io/v1alpha1
rbac.authorization.k8s.io/v1beta1
rook.io/v1beta1
settings.k8s.io/v1alpha1
storage.k8s.io/v1
storage.k8s.io/v1beta1
v1
```

It's pretty straightforward to write your own API server now with the break-out of [`k8s.io/apiserver`](https://github.com/kubernetes/apiserver).
The `sig-api-machinery` team has also given us a sample implementation: [`k8s.io/sample-apiserver`](https://github.com/kubernetes/sample-apiserver).

The sample API Server called wardle, contains one API group: `wardle.k8s.io/v1alpha1` and one API resource in that group: `Flunder`
This guide shows how easy it will be to extend the Kubernetes API in the future.

The sample API Server saves its data to a separate etcd instance running in-cluster. Notice the PersistentVolume that is created for etcd for that purpose.
Note that in the future, the etcd Operator should probably be used for running etcd instead of running it manually like now.

```console
$ kubectl apply -f demos/sample-apiserver/wardle.yaml
namespace "wardle" created
persistentvolumeclaim "etcd-pv-claim" created
serviceaccount "apiserver" created
clusterrolebinding "wardle:system:auth-delegator" created
rolebinding "wardle-auth-reader" created
deployment "wardle-apiserver" created
service "api" created
apiservice "v1alpha1.wardle.k8s.io" created

$ kubectl get secret rook-rbd-user -oyaml | sed "/resourceVer/d;/uid/d;/self/d;/creat/d;/namespace/d" | kubectl -n wardle apply -f -
```

After a few minutes, when the extended API server is up and running, `kubectl` will auto-discover that API group and it will be possible to
create, list and delete Flunder objects just as any other API object.

```console
$ kubectl api-versions
apiregistration.k8s.io/v1alpha1
apps/v1beta1
authentication.k8s.io/v1
authentication.k8s.io/v1beta1
authorization.k8s.io/v1
authorization.k8s.io/v1beta1
autoscaling/v1
autoscaling/v2alpha1
batch/v1
batch/v2alpha1
certificates.k8s.io/v1beta1
extensions/v1beta1
policy/v1beta1
rbac.authorization.k8s.io/v1alpha1
rbac.authorization.k8s.io/v1beta1
rook.io/v1beta1
settings.k8s.io/v1alpha1
storage.k8s.io/v1
storage.k8s.io/v1beta1
v1
***wardle.k8s.io/v1alpha1***

$ # There is no foobarbaz resource, but the flunders resource does now exist
$ kubectl get foobarbaz
the server doesn't have a resource type "foobarbaz"

$ kubectl get flunders
No resources found.

$ kubectl apply -f demos/sample-apiserver/my-flunder.yaml
flunder "my-first-flunder" created
```

If you want to make sure this is real, you can check the etcd database running in-cluster with this command:

```console
$ kubectl -n wardle exec -it $(kubectl -n wardle get po -l app=wardle-apiserver -otemplate --template "{{ (index .items 0).metadata.name}}") -c etcd /bin/sh -- -c \
	"ETCDCTL_API=3 etcdctl get /registry/wardle.kubernetes.io/registry/wardle.kubernetes.io/wardle.k8s.io/flunders/my-first-flunder"
/registry/wardle.kubernetes.io/registry/wardle.kubernetes.io/wardle.k8s.io/flunders/my-first-flunder
{"kind":"Flunder","apiVersion":"wardle.k8s.io/v1alpha1","metadata":{"name":"my-first-flunder","uid":"8e4e1029-0c14-11e7-928a-def758206707","creationTimestamp":"2017-03-18T19:53:28Z","labels":{"sample-label":"true"},"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"wardle.k8s.io/v1alpha1\",\"kind\":\"Flunder\",\"metadata\":{\"annotations\":{},\"labels\":{\"sample-label\":\"true\"},\"name\":\"my-first-flunder\",\"namespace\":\"default\"}}\n"}},"spec":{},"status":{}}
```

Conclusion, the Flunder object we created was saved in the separate etcd instance!

### Deploying the Prometheus Operator for monitoring Services in the cluster

[Prometheus](prometheus.io) is a great monitoring solution, and combining it with Kubernetes makes it even more awesome!

```console
$ kubectl apply -f demos/monitoring/prometheus-operator.yaml
clusterrole "prometheus-operator" created
serviceaccount "prometheus-operator" created
clusterrolebinding "prometheus-operator" created
deployment "prometheus-operator" created

$ kubectl apply -f demos/monitoring/sample-prometheus-instance.yaml
clusterrole "prometheus" created
serviceaccount "prometheus" created
clusterrolebinding "prometheus" created
deployment "sample-metrics-app" created
service "sample-metrics-app" created
servicemonitor "sample-metrics-app" created
prometheus "sample-metrics-prom" created
service "sample-metrics-prom" created

$ kubectl get svc
NAME                  CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes            10.96.0.1       <none>        443/TCP          30m
prometheus-operated   None            <none>        9090/TCP         4m
sample-metrics-app    10.108.65.91    <none>        8080/TCP         4m
sample-metrics-prom   10.108.71.184   <nodes>       9090:30999/TCP   4m
```


### Deploying a custom metrics API Server

```console
$ kubectl apply -f demos/monitoring/custom-metrics.yaml
namespace "custom-metrics" created
serviceaccount "custom-metrics-apiserver" created
clusterrolebinding "custom-metrics:system:auth-delegator" created
rolebinding "custom-metrics-auth-reader" created
clusterrole "custom-metrics-read" created
clusterrolebinding "custom-metrics-read" created
deployment "custom-metrics-apiserver" created
service "api" created
apiservice "v1alpha1.custom-metrics.metrics.k8s.io" created
clusterrole "custom-metrics-server-resources" created
clusterrolebinding "hpa-controller-custom-metrics" created
```


```console
$ kubectl apply -f demos/sample-webservice/nginx.yaml
deployment "my-nginx" created
service "my-nginx" created

$ kubectl apply -f demos/monitoring/sample-hpa.yaml
horizontalpodautoscaler "my-hpa" created
```

### Acknowledgements / More reference

Some people that helped me 
