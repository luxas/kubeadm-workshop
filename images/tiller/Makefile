REGISTRY?=luxas
VERSION?=v2.6.1
TEMP_DIR:=$(shell mktemp -d)

all: push
download: 
	git clone https://github.com/luxas/helm $(TEMP_DIR) -b backport_crossbuild_261

push: download
	make -C $(TEMP_DIR) bootstrap-dockerized docker-push DOCKER_REGISTRY=docker.io IMAGE_PREFIX=$(REGISTRY) VERSION=$(VERSION)
