REGISTRY?=luxas
IMAGE?=node
TEMP_DIR:=$(shell mktemp -d)
ARCH?=amd64
ALL_ARCH=amd64 arm arm64
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64
VERSION?=$(shell curl -sSL https://raw.githubusercontent.com/nodejs/docker-node/master/7.7/alpine/Dockerfile | grep "ENV NODE_VERSION" | awk '{print $$3}')

ifeq ($(ARCH),arm)
	BASEIMAGE?=armhf\\/alpine:3.5
	QEMUARCH=arm
endif
ifeq ($(ARCH),arm64)
	BASEIMAGE?=aarch64\\/alpine:3.5
	QEMUARCH=aarch64
endif

all: build
build:

ifeq ($(ARCH),amd64)
	docker pull node:alpine
	docker tag node:alpine $(REGISTRY)/$(IMAGE)-$(ARCH):$(VERSION)
else
	curl -sSL https://raw.githubusercontent.com/nodejs/docker-node/master/7.7/alpine/Dockerfile > $(TEMP_DIR)/Dockerfile
	cd $(TEMP_DIR) && sed -e "s/alpine:[0-9.]*/$(BASEIMAGE)\nCOPY qemu-$(QEMUARCH)-static \\/usr\\/bin\\//" -i Dockerfile

	# Register /usr/bin/qemu-ARCH-static as the handler for ARM binaries in the kernel
	docker run --rm --privileged multiarch/qemu-user-static:register --reset
	curl -sSL --retry 5 https://github.com/multiarch/qemu-user-static/releases/download/v2.7.0/x86_64_qemu-${QEMUARCH}-static.tar.gz | tar -xz -C ${TEMP_DIR}

	docker build -t $(REGISTRY)/$(IMAGE)-$(ARCH):$(VERSION) $(TEMP_DIR)
endif

	rm -r $(TEMP_DIR)

push-%:
	$(MAKE) ARCH=$* build
	docker push $(REGISTRY)/$(IMAGE)-$*:$(VERSION)
	docker tag $(REGISTRY)/$(IMAGE)-$*:$(VERSION) $(REGISTRY)/$(IMAGE)-$*:latest
	docker push $(REGISTRY)/$(IMAGE)-$*:latest

push: ./manifest-tool $(addprefix push-,$(ALL_ARCH))
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/$(IMAGE)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMAGE):$(VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/$(IMAGE)-ARCH:latest --target $(REGISTRY)/$(IMAGE):latest

./manifest-tool:
	curl -sSL https://github.com/estesp/manifest-tool/releases/download/v0.5.0/manifest-tool-linux-amd64 > manifest-tool
	chmod +x manifest-tool
