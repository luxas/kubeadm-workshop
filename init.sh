
kubeadm init --config kubeadm.yaml

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl create secret -n kube-system generic weave-passwd --from-literal=weave-passwd=$(hexdump -n 16 -e '4/4 "%08x" 1 "\n"' /dev/random)
kubectl apply -n kube-system -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&password-secret=weave-passwd"
kubectl taint nodes --all node-role.kubernetes.io/master-

# Deploy the Dashboard
curl -sSL https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml | sed "s|gcr.io/google_containers/kubernetes-dashboard-amd64:.*|luxas/kubernetes-dashboard:v1.7.1|" | kubectl apply -f -
kubectl apply -f demos/dashboard/ingress.yaml

# Deploy metrics-server and Heapster
kubectl apply -f demos/monitoring/metrics-server.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml
curl -sSL https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml | \
	sed "s|image:.*|image: luxas/heapster:v1.4.0|" | kubectl apply -f -

kubectl apply -f demos/loadbalancing/traefik-common.yaml
kubectl apply -f demos/loadbalancing/traefik-ngrok.yaml

# Install the Rook and Prometheus operators
ROOK_BRANCH=${ROOK_BRANCH:-"release-0.5"}
kubectl apply -f https://raw.githubusercontent.com/rook/rook/${ROOK_BRANCH}/cluster/examples/kubernetes/rook-operator.yaml
kubectl apply -f demos/monitoring/prometheus-operator.yaml

echo "Waiting for the Rook and Prometheus operators to create the TPRs/CRDs"
while [[ $(kubectl get cluster; echo $?) == 1 ]]; do sleep 1; done
while [[ $(kubectl get prometheus; echo $?) == 1 ]]; do sleep 1; done

# Requires the Rook and Prometheus API groups
kubectl apply -f https://raw.githubusercontent.com/rook/rook/${ROOK_BRANCH}/cluster/examples/kubernetes/rook-cluster.yaml
kubectl apply -f https://raw.githubusercontent.com/rook/rook/${ROOK_BRANCH}/cluster/examples/kubernetes/rook-storageclass.yaml
kubectl patch storageclass rook-block -p '{"metadata":{"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

echo "Waiting for rook to create a Secret"
while [[ $(kubectl get secret rook-rook-user; echo $?) == 1 ]]; do sleep 1; done

# Set up the rook Secret for other namespaces than default
kubectl get secret rook-rook-user -oyaml | sed "/resourceVer/d;/uid/d;/self/d;/creat/d;/namespace/d" | kubectl -n kube-system apply -f -
kubectl create ns wardle
kubectl get secret rook-rook-user -oyaml | sed "/resourceVer/d;/uid/d;/self/d;/creat/d;/namespace/d" | kubectl -n wardle apply -f -


kubectl apply -f demos/monitoring/influx-grafana.yaml

# Demo the autoscaling based on custom metrics feature
kubectl apply -f demos/monitoring/sample-prometheus-instance.yaml
kubectl apply -f demos/monitoring/sample-metrics-app.yaml
kubectl apply -f demos/monitoring/custom-metrics.yaml
kubectl create clusterrolebinding allowall-cm --clusterrole custom-metrics-server-resources --user system:anonymous

# Setup helm and install tiller
helm init
kubectl -n kube-system create serviceaccount tiller
kubectl -n kube-system set serviceaccount deploy tiller-deploy tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount kube-system:tiller
kubectl -n kube-system set image deploy/tiller-deploy tiller=luxas/tiller:v2.6.1

# Demo an aggregated API server
kubectl apply -f demos/sample-apiserver/wardle.yaml
while [[ $(kubectl get flunder; echo $?) == 1 ]]; do sleep 1; done
kubectl apply -f demos/sample-apiserver/my-flunder.yaml
