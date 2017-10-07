REGISTRY?=luxas
IMAGE?=sample-apiserver
TEMP_DIR:=$(shell mktemp -d)
ARCH?=amd64
ALL_ARCH=amd64 arm arm64
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64

COMMIT?=aa1ce319891e390026f7f7759dceb03c99156a4b
VERSION?=v0.3.0

ifeq ($(ARCH),amd64)
	BASEIMAGE?=busybox
endif
ifeq ($(ARCH),arm)
	BASEIMAGE?=arm32v7/busybox
endif
ifeq ($(ARCH),arm64)
	BASEIMAGE?=arm64v8/busybox
endif

all: build
build:
	cp Dockerfile $(TEMP_DIR)
	cd $(TEMP_DIR) && sed -i "s|BASEIMAGE|$(BASEIMAGE)|g" Dockerfile

	docker run -it -v $(TEMP_DIR):/build -e GOARCH=$(ARCH) golang:1.8 /bin/bash -c "\
		git clone https://github.com/kubernetes/sample-apiserver /go/src/k8s.io/sample-apiserver && \
		cd /go/src/k8s.io/sample-apiserver && git checkout $(COMMIT) && \
		CGO_ENABLED=0 go build -a -tags netgo -o /build/sample-apiserver k8s.io/sample-apiserver"

	docker build -t $(REGISTRY)/$(IMAGE)-$(ARCH):$(VERSION) $(TEMP_DIR)

push-%:
	$(MAKE) ARCH=$* build
	docker push $(REGISTRY)/$(IMAGE)-$*:$(VERSION)

push: ./manifest-tool $(addprefix push-,$(ALL_ARCH))
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/$(IMAGE)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMAGE):$(VERSION)

./manifest-tool:
	curl -sSL https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-amd64 > manifest-tool
	chmod +x manifest-tool
