REGISTRY?=luxas
IMAGE?=k8s-prometheus-adapter
ALL_ARCH=amd64 arm arm64 ppc64le s390x
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64,linux/ppc64le,linux/s390x
VENDOR_DOCKERIZED=1
VERSION?=v0.1.0
TEMP_DIR:=$(shell mktemp -d)
export

all: build
download: 
	git clone https://github.com/DirectXMan12/k8s-prometheus-adapter $(TEMP_DIR) -b $(VERSION)

build: download
	REGISTRY=$(REGISTRY) VERSION=$(VERSION) IMAGE=$(IMAGE) VENDOR_DOCKERIZED=$(VENDOR_DOCKERIZED) ALL_ARCH=$(ALL_ARCH) ML_PLATFORMS=$(ML_PLATFORMS) make -C $(TEMP_DIR) build

push: download
	REGISTRY=$(REGISTRY) VERSION=$(VERSION) IMAGE=$(IMAGE) VENDOR_DOCKERIZED=$(VENDOR_DOCKERIZED) ALL_ARCH=$(ALL_ARCH) ML_PLATFORMS=$(ML_PLATFORMS) make -C $(TEMP_DIR) push
