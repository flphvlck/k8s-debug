include .vars

all: build push

build:
	docker build --provenance=false --sbom=false --no-cache --platform=linux/amd64,linux/arm64 -t $(IMAGE_REPOSITORY):root -f Dockerfile-root .
	docker build --provenance=false --sbom=false --no-cache --platform=linux/amd64,linux/arm64 -t $(IMAGE_REPOSITORY):nonroot -f Dockerfile-nonroot .
	docker tag $(IMAGE_REPOSITORY):nonroot $(IMAGE_REPOSITORY):latest
     
push:
	docker push $(IMAGE_REPOSITORY):root
	docker push $(IMAGE_REPOSITORY):nonroot
	docker push $(IMAGE_REPOSITORY):latest

help:
	@echo "Usage: make {all|build|push|help}"
