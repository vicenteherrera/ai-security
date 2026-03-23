
REGISTRY ?= quay.io
IMAGE_NAME ?= vicenteherrera/pickle-jupyter
IMAGE_TAG ?= latest
IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
BUILD_PLATFORMS ?= linux/amd64,linux/arm64

all: install run

.PHONY: install
# Install Python dependencies using Poetry
install:
	poetry install

.PHONY: run
# Install deps and launch Jupyter Notebook locally
run: install
	poetry run jupyter notebook

.PHONY: clean
# Remove generated files, Poetry env, and stop/remove container and image
clean:
	rm -f linear_regression.pkl compromise.bin
	poetry env remove $$(poetry env info -e)
	-docker stop $$(docker ps -q --filter ancestor=$(IMAGE)) 2>/dev/null
	-docker rmi $(IMAGE) 2>/dev/null

.PHONY: uv-install
# Install Python dependencies using uv (creates a virtual environment automatically)
uv-install:
	uv sync

.PHONY: uv-run
# Install deps and launch Jupyter Notebook locally using uv
uv-run: uv-install
	uv run jupyter notebook

.PHONY: uv-clean
# Remove generated files, uv virtual env, and stop/remove container and image
uv-clean:
	rm -f linear_regression.pkl compromise.bin
	rm -rf .venv
	-docker stop $$(docker ps -q --filter ancestor=$(IMAGE)) 2>/dev/null
	-docker rmi $(IMAGE) 2>/dev/null

.PHONY: build
# Build the container image
build:
	docker build -t $(IMAGE) .

.PHONY: build-multiplatform
# Build the container image for multiple platforms
build-multiplatform:
	docker buildx build --platform $(BUILD_PLATFORMS) -t $(IMAGE) .

.PHONY: run-container
# Build and run the container, exposing Jupyter on port 8888
run-container: build
	docker run --rm -p 8888:8888 $(IMAGE)

.PHONY: push
# Push the container image to the registry
push: build
	docker push $(IMAGE)
