REGISTRY?=luxas
ARCH?=amd64
ALL_ARCH=amd64 arm arm64
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64

GCR_REGISTRY?=gcr.io/google_containers
HEAPSTER_VERSION?=v1.3.0
GRAFANA_VERSION?=v4.0.2
INFLUXDB_VERSION?=v1.1.1
DASHBOARD_VERSION?=v1.6.0
ETCD_VERSION?=3.0.17
PROXY_VERSION?=$(shell curl -sSL dl.k8s.io/release/latest.txt)

tag-%:
	docker pull $(GCR_REGISTRY)/$*
	docker tag $(GCR_REGISTRY)/$* $(REGISTRY)/$*
	docker push $(REGISTRY)/$*

push-%:
	$(MAKE) tag-heapster-$*:$(HEAPSTER_VERSION)
	$(MAKE) tag-heapster-grafana-$*:$(GRAFANA_VERSION)
	$(MAKE) tag-heapster-influxdb-$*:$(INFLUXDB_VERSION)
	$(MAKE) tag-kubernetes-dashboard-$*:$(DASHBOARD_VERSION)
	$(MAKE) tag-etcd-$*:$(ETCD_VERSION)
	$(MAKE) tag-kube-proxy-$*:$(PROXY_VERSION)

push: ./manifest-tool $(addprefix push-,$(ALL_ARCH))
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/heapster-ARCH:$(HEAPSTER_VERSION) --target $(REGISTRY)/heapster:$(HEAPSTER_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/heapster-grafana-ARCH:$(GRAFANA_VERSION) --target $(REGISTRY)/heapster-grafana:$(GRAFANA_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/heapster-influxdb-ARCH:$(INFLUXDB_VERSION) --target $(REGISTRY)/heapster-influxdb:$(INFLUXDB_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/kubernetes-dashboard-ARCH:$(DASHBOARD_VERSION) --target $(REGISTRY)/kubernetes-dashboard:$(DASHBOARD_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/etcd-ARCH:$(ETCD_VERSION) --target $(REGISTRY)/etcd:$(ETCD_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/kube-proxy-ARCH:$(PROXY_VERSION) --target $(REGISTRY)/kube-proxy:$(PROXY_VERSION)

./manifest-tool:
	curl -sSL https://github.com/estesp/manifest-tool/releases/download/v0.4.0/manifest-tool-linux-amd64 > manifest-tool
	chmod +x manifest-tool
