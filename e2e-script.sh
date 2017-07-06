kubeadm init --config kubeadm.yaml

mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

ROOK_BRANCH=${ROOK_BRANCH:-"release-0.4"}

kubectl apply -f https://git.io/weave-kube-1.6
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl apply -f demos/dashboard/dashboard.yaml
kubectl apply -f demos/monitoring/heapster.yaml
# TODO: Start using PVs/PVCs for influxdb and grafana
kubectl apply -f demos/monitoring/influx-grafana.yaml
kubectl apply -f demos/loadbalancing/traefik-common.yaml
kubectl apply -f demos/loadbalancing/traefik-ngrok.yaml
kubectl apply -f demos/dashboard/ingress.yaml
kubectl apply -f https://raw.githubusercontent.com/rook/rook/${ROOK_BRANCH}/demo/kubernetes/rook-operator.yaml
kubectl apply -f demos/monitoring/prometheus-operator.yaml

echo "Waiting for the Rook and Prometheus operators to create the TPRs/CRDs"
while [[ $(kubectl get cluster; echo $?) == 1 ]]; do sleep 1; done
while [[ $(kubectl get prometheus; echo $?) == 1 ]]; do sleep 1; done

# Requires the Rook and Prometheus API groups
kubectl apply -f https://raw.githubusercontent.com/rook/rook/${ROOK_BRANCH}/demo/kubernetes/rook-cluster.yaml
kubectl apply -f https://raw.githubusercontent.com/rook/rook/${ROOK_BRANCH}/demo/kubernetes/rook-storageclass.yaml
kubectl apply -f demos/monitoring/sample-prometheus-instance.yaml
kubectl apply -f demos/monitoring/sample-metrics-app.yaml
kubectl apply -f demos/monitoring/custom-metrics.yaml
kubectl create clusterrolebinding allowall-cm --clusterrole custom-metrics-server-resources --user system:anonymous

echo "Waiting for rook to create a Secret"
while [[ $(kubectl get secret rook-rook-user; echo $?) == 1 ]]; do sleep 1; done

# Requires the rook-rook-user
kubectl get secret rook-rook-user -oyaml | sed "/resourceVer/d;/uid/d;/self/d;/creat/d;/namespace/d" | kubectl -n kube-system apply -f -
kubectl create ns wardle
kubectl get secret rook-rook-user -oyaml | sed "/resourceVer/d;/uid/d;/self/d;/creat/d;/namespace/d" | kubectl -n wardle apply -f -

helm init

kubectl -n kube-system create serviceaccount tiller
kubectl -n kube-system patch deploy tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccountName":"tiller"}}}}'
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount kube-system:tiller


kubectl apply -f demos/sample-apiserver/wardle.yaml
while [[ $(kubectl get flunder; echo $?) == 1 ]]; do sleep 1; done
kubectl apply -f demos/sample-apiserver/my-flunder.yaml

#kubectl patch storageclass rook-block -p '{"metadata":{"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
