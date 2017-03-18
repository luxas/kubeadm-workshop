### Workshop:

## Building a multi-architecture Kubernetes cluster on bare metal with `kubeadm`

Hi and welcome to this tutorial and demonstration of how to build a bare-metal Kubernetes cluster with kubeadm!

I'm one of the main kubeadm developers and very excited about bare metal as well, 
so I thought showing some of the things you can do with Kubernetes/kubeadm would be a great fit!

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

SSH 

As mentioned earlier, experimental features of different kinds will be used in this tutorial to show off the latest and greatest features in Kubernetes.

kubeadm for example, can take options from a configuration file in order to be customized easily.
But the API exposed in v1.6 is _not_ stable, and under heavy development. So this will definitely change (to the better) in time for v1.7.

Anyway, the configuration file we'll use here looks like this in `kubeadm.yaml`:

```yaml
kind: MasterConfiguration
apiVersion: kubeadm.k8s.io/v1alpha1
networking:
  podSubnet: "10.244.0.0/16"
controllerManagerExtraArgs:
  controllers: "*,-persistentvolume-binder"
  horizontal-pod-autoscaler-use-rest-clients: "true"
  node-monitor-grace-period: "10s"
apiServerExtraArgs:
  runtime-config: "api/all=true"
  feature-flags: "UseTaintBasedEvictions=true"
#selfHosted: true
```

Disable CRI on the master:
```
echo "Environment=\"KUBELET_EXTRA_ARGS=--enable-cri=false\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
```

```bash
KUBE_HYPERKUBE_IMAGE=luxas/demo-hyperkube-amd64:v1.6.0-kubeadm-workshop kubeadm init --config kubeadm.yaml
```

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

### Setting up the worker nodes

```
kubeadm join --token <foo> <master-ip>:<master-port>
```

### Deploying the Pod networking layer

```bash
kubectl apply -f https://raw.githubusercontent.com/weaveworks/weave/1.9/prog/weave-kube/weave-daemonset-k8s-1.6.yaml
```

### Deploying the Dashboard and Heapster

```
kubectl create -f demos/dashboard/dashboard.yaml
kubectl -n kube-system get service kubernetes-dashboard -o template --template="{{ (index .spec.ports 0).nodePort }}"
```

```
kubectl create -f demos/monitoring/heapster.yaml
```

### Deploying an Ingress Controller for exposing HTTP services

```
kubectl create -f demos/loadbalancing/traefik-ngrok.yaml

curl -sSL $(kubectl -n kube-system get svc ngrok -o template --template "{{.spec.clusterIP}}")/api/tunnels | jq ".tunnels[0].public_url"
```

### Deploying a persistent storage layer on top of Kubernetes with Rook

```
kubectl create -f demos/storage/rook/operator.yaml
kubectl create -f demos/storage/rook/pvcontroller.yaml

kubectl create -f demos/storage/rook/cluster.yaml

export MONS=$(kubectl -n rook get pod mon0 mon1 mon2 -o json|jq ".items[].status.podIP"|tr -d "\""|sed -e 's/$/:6790/'|paste -s -d, -)
sed 's#INSERT_HERE#'$MONS'#' demos/storage/rook/storageclass.yaml | kubectl create -f -

kubectl get secret rook-secret -oyaml | sed "/resourceVer/d;/uid/d;/self/d;/creat/d;s/default/kube-system/"
```

### Deploying InfluxDB and Grafana for storing and visualizing CPU and memory metrics

```
kubectl create -f demos/monitoring/influx-grafana.yaml
```

### Sample API Server

```
kubectl create -f demos/sample-apiserver/wardle.yaml

kubectl create -f demos/sample-apiserver/flunder.yaml
```

```
kubectl -n wardle exec -it $(kubectl -n wardle get po -l app=wardle-apiserver -otemplate --template "{{ (index .items 0).metadata.name}}") -c etcd /bin/sh -- -c \
	"ETCDCTL_API=3 etcdctl get /registry/wardle.kubernetes.io/registry/wardle.kubernetes.io/wardle.k8s.io/flunders/my-first-flunder"
```


### Deploying the Prometheus Operator for monitoring Services in the cluster

```
kubectl create -f demos/monitoring/prometheus-operator.yaml

kubectl create -f demos/monitoring/sample-prometheus-instance.yaml
```
