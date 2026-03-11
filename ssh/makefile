.PHONY: build push pull build-and-push run stop

REGISTRY ?= quay.io/vicenteherrera
IMAGE_NAME ?= example-ssh
IMAGE_TAG ?= latest
IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

# Platforms to build for (comma-separated). Default builds for Intel (amd64) and ARM (arm64).
BUILD_PLATFORMS ?= linux/amd64,linux/arm64

# Use docker buildx to build a multi-arch image and push the manifest to the registry.
# Note: buildx requires a builder with multi-platform support. If you don't have one,
# create it with: docker buildx create --use
build:
	docker buildx build --platform $(BUILD_PLATFORMS) -t $(IMAGE) .

# The build target already pushes the multi-arch image. Keep `push` for compatibility.
push:
	docker push $(IMAGE)

pull:
	docker pull $(IMAGE)

build-and-push: build
	@echo "Build and push complete: $(IMAGE)"

run:
	docker run -d -p 2222:22 --name ssh-lab $(IMAGE)

stop:
	docker stop ssh-lab || true
	docker rm ssh-lab || true