REGISTRY?=luxas
IMAGE?=prometheus-operator
TEMP_DIR:=$(shell mktemp -d)
ARCH?=amd64
ALL_ARCH=amd64 arm arm64
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64

VERSION?=v0.7.1

ifeq ($(ARCH),amd64)
	BASEIMAGE?=busybox
endif
ifeq ($(ARCH),arm)
	BASEIMAGE?=armhf/busybox
endif
ifeq ($(ARCH),arm64)
	BASEIMAGE?=aarch64/busybox
endif

all: build
build:
	cp Dockerfile $(TEMP_DIR)
	cd $(TEMP_DIR) && sed -i "s|BASEIMAGE|$(BASEIMAGE)|g" Dockerfile

	docker run -it -v $(TEMP_DIR):/build -e GOARCH=$(ARCH) golang:1.7 /bin/bash -c "\
		git clone https://github.com/luxas/prometheus-operator -b fix_relabeling /go/src/github.com/coreos/prometheus-operator && \
		CGO_ENABLED=0 go build -a -tags netgo -o /build/operator github.com/coreos/prometheus-operator/cmd/operator"

	docker build -t $(REGISTRY)/$(IMAGE)-$(ARCH):$(VERSION) $(TEMP_DIR)
	rm -r $(TEMP_DIR)

push-%:
	$(MAKE) ARCH=$* build
	docker push $(REGISTRY)/$(IMAGE)-$*:$(VERSION)

push: ./manifest-tool $(addprefix push-,$(ALL_ARCH))
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/$(IMAGE)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMAGE):$(VERSION)

./manifest-tool:
	curl -sSL https://github.com/estesp/manifest-tool/releases/download/v0.4.0/manifest-tool-linux-amd64 > manifest-tool
	chmod +x manifest-tool
