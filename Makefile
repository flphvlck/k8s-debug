help:
	@echo "Usage: make (podman|docker)"
	@echo "podman - build and push images with Podman"
	@echo "docker - build and push images with Docker"


podman: podman-build podman-push

podman-build:
	-podman manifest exists k8s-debug:root && podman manifest rm k8s-debug:root
	-podman manifest exists k8s-debug:nonroot && podman manifest rm k8s-debug:nonroot
	podman manifest create k8s-debug:root
	podman manifest create k8s-debug:nonroot
	podman rmi --ignore k8s-debug:root-amd64 k8s-debug:root-arm64 k8s-debug:nonroot-amd64 k8s-debug:nonroot-arm64
	podman build --no-cache --platform linux/amd64 --tag k8s-debug:root-amd64 --file Dockerfile-root --manifest k8s-debug:root .
	podman build --no-cache --platform linux/arm64 --tag k8s-debug:root-arm64 --file Dockerfile-root --manifest k8s-debug:root .
	podman build --no-cache --platform linux/amd64 --tag k8s-debug:nonroot-amd64 --file Dockerfile-nonroot --manifest k8s-debug:nonroot .
	podman build --no-cache --platform linux/arm64 --tag k8s-debug:nonroot-arm64 --file Dockerfile-nonroot --manifest k8s-debug:nonroot .

podman-push:
	podman manifest push k8s-debug:root quay.io/filiphavlicek/k8s-debug:root
	podman manifest push k8s-debug:nonroot quay.io/filiphavlicek/k8s-debug:nonroot
	podman manifest push k8s-debug:nonroot quay.io/filiphavlicek/k8s-debug:latest
	podman manifest push k8s-debug:root docker.io/flphvlck/k8s-debug:root
	podman manifest push k8s-debug:nonroot docker.io/flphvlck/k8s-debug:nonroot
	podman manifest push k8s-debug:nonroot docker.io/flphvlck/k8s-debug:latest

docker: docker-build docker-push

docker-build:
	docker build --provenance=false --sbom=false --no-cache --platform=linux/amd64,linux/arm64 -t quay.io/filiphavlicek/k8s-debug:root -t docker.io/flphvlck/k8s-debug:root -f Dockerfile-root .
	docker build --provenance=false --sbom=false --no-cache --platform=linux/amd64,linux/arm64 -t quay.io/filiphavlicek/k8s-debug:nonroot -t quay.io/filiphavlicek/k8s-debug:latest -t docker.io/flphvlck/k8s-debug:nonroot -f Dockerfile-nonroot .

docker-push:
	docker push --all-tags quay.io/filiphavlicek/k8s-debug
	docker push --all-tags docker.io/flphvlck/k8s-debug

# vim: set noexpandtab:
