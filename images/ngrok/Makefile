REGISTRY?=luxas
IMAGE?=ngrok
TEMP_DIR:=$(shell mktemp -d)
ARCH?=amd64
ALL_ARCH=amd64 arm arm64
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64

VERSION?=v2.1.18
VERSION_HASH?=4VmDzA7iaHb
URL?=https://bin.equinox.io/c/$(VERSION_HASH)/ngrok-stable-linux-$(ARCH).zip

all: build
build:
	curl -sSL $(URL) > $(TEMP_DIR)/ngrok.zip
	cd $(TEMP_DIR) && unzip ngrok.zip
	cp Dockerfile $(TEMP_DIR)

	docker build -t $(REGISTRY)/$(IMAGE)-$(ARCH):$(VERSION) $(TEMP_DIR)
	rm -r $(TEMP_DIR)

push-%:
	$(MAKE) ARCH=$* build
	docker push $(REGISTRY)/$(IMAGE)-$*:$(VERSION)

push: ./manifest-tool $(addprefix push-,$(ALL_ARCH))
	./manifest-tool push from-args --platforms $(ML_PLATFORMS) --template $(REGISTRY)/$(IMAGE)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMAGE):$(VERSION)

./manifest-tool:
	curl -sSL https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-amd64 > manifest-tool
	chmod +x manifest-tool
