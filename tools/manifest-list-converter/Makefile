REGISTRY?=luxas
ARCH?=amd64
ALL_ARCH=amd64 arm arm64
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64

GCR_REGISTRY?=gcr.io/google_containers
SC_REGISTRY?=quay.io/kubernetes-service-catalog
HEAPSTER_VERSION?=v1.4.0
GRAFANA_VERSION?=v4.4.3
INFLUXDB_VERSION?=v1.3.3
DASHBOARD_VERSION?=v1.6.3
ETCD_VERSION?=3.0.17
SERVICE_CATALOG_VERSION?=v0.0.17
HELM_VERSION?=v2.6.1
PROXY_VERSION?=$(shell curl -sSL dl.k8s.io/release/stable-1.7.txt)

gcr-tag-%:
	docker pull $(GCR_REGISTRY)/$*
	docker tag $(GCR_REGISTRY)/$* $(REGISTRY)/$*
	docker push $(REGISTRY)/$*

sc-tag-%:
	docker pull $(SC_REGISTRY)/$*
	docker tag $(SC_REGISTRY)/$* $(REGISTRY)/service-catalog-$*
	docker push $(REGISTRY)/service-catalog-$*

luxas-tag-%:
	docker pull luxas/$*

push-%:
	$(MAKE) gcr-tag-heapster-$*:$(HEAPSTER_VERSION)
	$(MAKE) luxas-tag-heapster-grafana-$*:$(GRAFANA_VERSION)
	$(MAKE) luxas-tag-heapster-influxdb-$*:$(INFLUXDB_VERSION)
	$(MAKE) gcr-tag-kubernetes-dashboard-$*:$(DASHBOARD_VERSION)
	$(MAKE) gcr-tag-etcd-$*:$(ETCD_VERSION)
	$(MAKE) gcr-tag-kube-proxy-$*:$(PROXY_VERSION)
	$(MAKE) sc-tag-apiserver-$*:$(SERVICE_CATALOG_VERSION)
	$(MAKE) sc-tag-controller-manager-$*:$(SERVICE_CATALOG_VERSION)
	$(MAKE) sc-tag-user-broker-$*:$(SERVICE_CATALOG_VERSION)
	$(MAKE) luxas-tag-tiller-$*:$(HELM_VERSION)

push: ./manifest-tool $(addprefix push-,$(ALL_ARCH))
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/heapster-ARCH:$(HEAPSTER_VERSION) --target $(REGISTRY)/heapster:$(HEAPSTER_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/heapster-grafana-ARCH:$(GRAFANA_VERSION) --target $(REGISTRY)/heapster-grafana:$(GRAFANA_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/heapster-influxdb-ARCH:$(INFLUXDB_VERSION) --target $(REGISTRY)/heapster-influxdb:$(INFLUXDB_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/kubernetes-dashboard-ARCH:$(DASHBOARD_VERSION) --target $(REGISTRY)/kubernetes-dashboard:$(DASHBOARD_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/etcd-ARCH:$(ETCD_VERSION) --target $(REGISTRY)/etcd:$(ETCD_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/kube-proxy-ARCH:$(PROXY_VERSION) --target $(REGISTRY)/kube-proxy:$(PROXY_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/service-catalog-apiserver-ARCH:$(SERVICE_CATALOG_VERSION) --target $(REGISTRY)/service-catalog-apiserver:$(SERVICE_CATALOG_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/service-catalog-controller-manager-ARCH:$(SERVICE_CATALOG_VERSION) --target $(REGISTRY)/service-catalog-controller-manager:$(SERVICE_CATALOG_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/service-catalog-user-broker-ARCH:$(SERVICE_CATALOG_VERSION) --target $(REGISTRY)/service-catalog-user-broker:$(SERVICE_CATALOG_VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/tiller-ARCH:$(HELM_VERSION) --target $(REGISTRY)/tiller:$(HELM_VERSION)

./manifest-tool:
	curl -sSL https://github.com/estesp/manifest-tool/releases/download/v0.6.0/manifest-tool-linux-amd64 > manifest-tool
	chmod +x manifest-tool
