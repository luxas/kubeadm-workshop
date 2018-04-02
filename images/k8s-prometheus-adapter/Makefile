REGISTRY?=luxas
IMAGE?=k8s-prometheus-adapter
VERSION?=v0.2.0
TEMP_DIR:=$(shell mktemp -d)

all: build
download:
	git clone https://github.com/DirectXMan12/k8s-prometheus-adapter $(TEMP_DIR) -b $(VERSION)

build: download
	make -C $(TEMP_DIR) build REGISTRY=$(REGISTRY) VERSION=$(VERSION) IMAGE=$(IMAGE) VENDOR_DOCKERIZED=1

push: download
	make -C $(TEMP_DIR) push REGISTRY=$(REGISTRY) VERSION=$(VERSION) IMAGE=$(IMAGE) VENDOR_DOCKERIZED=1
