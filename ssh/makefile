.PHONY: build push pull build-and-push run stop

REGISTRY ?= quay.io/vicenteherrera
IMAGE_NAME ?= example-ssh
IMAGE_TAG ?= latest
IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

build:
	docker build -t $(IMAGE) -f containerfile .

push: build
	docker push $(IMAGE)

pull:
	docker pull $(IMAGE)

build-and-push: build push
	@echo "Build and push complete: $(IMAGE)"

run:
	docker run -d -p 2222:22 --name ssh-lab $(IMAGE)

stop:
	docker stop ssh-lab || true
	docker rm ssh-lab || true