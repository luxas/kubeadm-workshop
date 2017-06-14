REGISTRY?=luxas
IMAGE?=prometheus
TEMP_DIR:=$(shell mktemp -d)
ARCH?=amd64
ALL_ARCH=amd64 arm arm64
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64

PROMARCH=$(ARCH)
ifeq ($(ARCH),amd64)
	BASEIMAGE=busybox
endif
ifeq ($(ARCH),arm)
	PROMARCH=armv7
	BASEIMAGE=armhf/busybox
endif
ifeq ($(ARCH),arm64)
	BASEIMAGE=aarch64/busybox
endif

VERSION_SEMVER=1.5.2
VERSION?=v$(VERSION_SEMVER)
URL?=https://github.com/prometheus/prometheus/releases/download/$(VERSION)/prometheus-$(VERSION_SEMVER).linux-$(PROMARCH).tar.gz

all: build
build:
	curl -sSL $(URL) | tar -xz -C $(TEMP_DIR) --strip-component=1
	cp Dockerfile $(TEMP_DIR)
	cd $(TEMP_DIR) && sed -i "s|BASEIMAGE|$(BASEIMAGE)|g" Dockerfile

	docker build -t $(REGISTRY)/$(IMAGE)-$(ARCH):$(VERSION) $(TEMP_DIR)
	rm -r $(TEMP_DIR)

push-%:
	$(MAKE) ARCH=$* build
	docker push $(REGISTRY)/$(IMAGE)-$*:$(VERSION)

push: ./manifest-tool $(addprefix push-,$(ALL_ARCH))
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/$(IMAGE)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMAGE):$(VERSION)

./manifest-tool:
	curl -sSL https://github.com/estesp/manifest-tool/releases/download/v0.5.0/manifest-tool-linux-amd64 > manifest-tool
	chmod +x manifest-tool
