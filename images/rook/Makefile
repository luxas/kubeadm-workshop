REGISTRY?=luxas
IMAGE_OPERATOR?=rook-operator
IMAGE_ROOKD?=rookd
TEMP_DIR:=$(shell mktemp -d)
ARCH?=amd64
ALL_ARCH=amd64 arm64
ML_PLATFORMS=linux/amd64,linux/arm64
QEMUVERSION=v2.7.0

VERSION?=v0.4.0-alpha.0

ifeq ($(ARCH),amd64)
	BASEIMAGE?=alpine
endif
ifeq ($(ARCH),arm)
	QEMUARCH=arm
	BASEIMAGE?=armhf/alpine
endif
ifeq ($(ARCH),arm64)
	QEMUARCH=aarch64
	BASEIMAGE?=aarch64/alpine
endif

all: build

./rook:
	git clone https://github.com/rook/rook

$(TEMP_DIR)/rookd $(TEMP_DIR)/rook-operator: ./rook
	cd rook \
		&& build/run make GOARCH=$(ARCH) build \
		&& git submodule update --init --recursive \
		&& cp bin/linux_$(ARCH)/rookd bin/linux_$(ARCH)/rook-operator $(TEMP_DIR)

build: $(TEMP_DIR)/rookd $(TEMP_DIR)/rook-operator
	cp Dockerfile.* $(TEMP_DIR)
	cd $(TEMP_DIR) && sed -i "s|BASEIMAGE|$(BASEIMAGE)|g" Dockerfile.*
	cd $(TEMP_DIR) && sed -i "s|QEMUARCH|$(QEMUARCH)|g" Dockerfile.*

ifeq ($(ARCH),amd64)
	# When building "normally" for amd64, remove the whole line, it has no part in the amd64 image
	cd $(TEMP_DIR) && sed -i "/CROSS_BUILD_/d" Dockerfile.*
else
	# When cross-building, only the placeholder "CROSS_BUILD_" should be removed
	# Register /usr/bin/qemu-ARCH-static as the handler for ARM binaries in the kernel
	docker run --rm --privileged multiarch/qemu-user-static:register --reset
	curl -sSL https://github.com/multiarch/qemu-user-static/releases/download/$(QEMUVERSION)/x86_64_qemu-$(QEMUARCH)-static.tar.gz | tar -xz -C $(TEMP_DIR)
	cd $(TEMP_DIR) && sed -i "s/CROSS_BUILD_//g" Dockerfile.*
endif

	cp /etc/ssl/certs/ca-certificates.crt $(TEMP_DIR)

	docker build -t $(REGISTRY)/$(IMAGE_OPERATOR)-$(ARCH):$(VERSION) -f $(TEMP_DIR)/Dockerfile.operator $(TEMP_DIR)
	docker build -t $(REGISTRY)/$(IMAGE_ROOKD)-$(ARCH):$(VERSION) -f $(TEMP_DIR)/Dockerfile.rookd $(TEMP_DIR)

push-%:
	$(MAKE) ARCH=$* build
	docker push $(REGISTRY)/$(IMAGE_OPERATOR)-$*:$(VERSION)
	docker push $(REGISTRY)/$(IMAGE_ROOKD)-$*:$(VERSION)

push: ./manifest-tool $(addprefix push-,$(ALL_ARCH))
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/$(IMAGE_OPERATOR)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMAGE_OPERATOR):$(VERSION)
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/$(IMAGE_ROOKD)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMAGE_ROOKD):$(VERSION)

./manifest-tool:
	curl -sSL https://github.com/estesp/manifest-tool/releases/download/v0.5.0/manifest-tool-linux-amd64 > manifest-tool
	chmod +x manifest-tool
