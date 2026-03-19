SHELL := /bin/bash

# Torch based models (.bin) require online connection so transformers library
# convert them, you never can just download files for offline use
# MODEL=lysandre/arxiv-nlp
# MODEL_EXT=*.bin
# REVISION=refs/pr/1

#  "stabilityai/stable-diffusion-2-1", revision="refs/pr/22", use_safetensors=True

# MODEL=hf-internal-testing/tiny-random-bert
# COMMIT=f171d7baecaf37b5da5a3616d8833b9969753535

MODEL=hf-internal-testing/tiny-random-bert
COMMIT=f171d7baecaf37b5da5a3616d8833b9969753535
MODEL_DIR=./.cache/huggingface/hub/${MODEL}

DIGEST_DIR=$(shell pwd)/digest
GPG_DIR=$(shell pwd)/gpg

CONTAINER_IMAGE=quay.io/vicenteherrera/test-llm
CONTAINER_TAG=no-model
CONTAINER_SHA=sha256:c0528e2f4bc9cd1381cdc4ad8d6cd35e4d1d2defe70572d85eb94f13a55fef22

SIGNER_ID=vicenteherrera@vicenteherrera.com
SIGNER_OIDC=https://accounts.google.com

CONFIG_FILE=$(shell for p in "env.txt" "../env.txt" "../../env.txt" "../../../env.txt"; do [[ -f "$$p" ]] && echo "$$p" && break; done || echo "")

# Show the available Make targets and usage examples.
all: help

.PHONY: help
# Print help text for model, signing, and attestation workflows.
help:
	@echo ""
	@echo "HELP"
	@echo ""
	@echo "# Download model"
	@echo "make download"
	@echo "---------------------------------------------------------"
	@echo "# Generate model digest SHA256"
	@echo "make run-digest-generate"
	@echo "# Validate model files with stored digest"
	@echo "make run-digest-validate"
	@echo "# Tamper with the model, so you see an error on validation if you validate again"
	@echo "make run-tamper-model"
	@echo "---------------------------------------------------------"
	@echo "# Sign model files with gpg detached signatures"
	@echo "make run-gpg-sign"
	@echo "# Validate model files with gpg detached signatures"
	@echo "make run-gpg-verify"
	@echo "---------------------------------------------------------"
	@echo "# Generate a CycloneDX BOM file from model"
	@echo "make run-mlbom-generate"
	@echo "# Generate a key pair for signing ML-BOMs with CycloneDX keygen"
	@echo "make mlbom-keygen"
	@echo "# Analyze the generated ML-BOM for version relationships"
	@echo "make run-mlbom-analyze"
	@echo "# Validate the generated ML-BOM for schema correctness"
	@echo "make run-mlbom-validate"
	@echo "# Sign the generated CycloneDX BOM file with a private key, store an unsigned reference copy"
	@echo "make run-mlbom-sign"
	@echo "# Verify the signature of the signed CycloneDX BOM file"
	@echo "make run-mlbom-verify-sign"
	@echo "# Conventional diff the generated and signed CycloneDX BOM files"
	@echo "make run-mlbom-diff"
	@echo "---------------------------------------------------------"
	@echo "# Generate a Cosign key pair for signing model files"
	@echo "make cosign-generate-key-pair"
	@echo "# Sign model files with cosign detached signatures"
	@echo "make run-cosign-sign"
	@echo "# Validate model files with cosign detached signatures"
	@echo "make run-cosign-verify"
	@echo "---------------------------------------------------------"
	@echo "# Verify signed container with inference code using public key and cosign against online rekor"
	@echo "make container-pull run-container-verify-key"

# tamper with model ----------------------------------------------------------------

.PHONY: run-tamper-model
# Append bytes to a model file to simulate tampering for validation tests.
run-tamper-model:
	echo -n '   ' >> ${MODEL_DIR}/config.json

# sha1sum digest ----------------------------------------------------------------

.PHONY: run-digest-generate
# Generate SHA1 digest files for each model artifact and a global digest.
run-digest-generate:
	@echo "Calculating hash of individual files for ${MODEL} into ${DIGEST_DIR}" && \
	mkdir -p "${DIGEST_DIR}/${MODEL}" && \
	cd "./.cache/huggingface/hub/" && \
	find "${MODEL}" -type f | while read file; do \
		digest_file="${DIGEST_DIR}/$$file.digest"; \
		mkdir -p "$$(dirname "$$digest_file")"; \
		sha1sum "$$file" | tee "$$digest_file"; \
	done
	@echo ""
	@echo "Calculating hash of global directory for ${MODEL}"
	@cd "./.cache/huggingface/hub/" && \
	find "${MODEL}" -type f \( -exec sha1sum "{}" \; \) | awk '{print $1}' | sort | sha1sum | tee "${DIGEST_DIR}.digest"
	

.PHONY: run-digest-validate
# Validate model files against stored per-file and global digest values.
run-digest-validate:
	@echo "Validating hash of individual files for ${MODEL} into ${DIGEST_DIR}" && \
	cd "./.cache/huggingface/hub/" && \
	find "${MODEL}" -type f -exec sh -c 'file="${DIGEST_DIR}/{}" && [ "$$(sha1sum {})" = "$$(cat "$$file.digest")" ] && echo "[ Valid ] $$file" || echo "[*ERROR*] $$file"' {} \; 
	@echo ""
	@echo "Validating hash of global directory for ${MODEL}"
	@cd "./.cache/huggingface/hub/" && \
	[ "$$(find "${MODEL}" -type f \( -exec sha1sum "{}" \; \) | awk '{print $1}' | sort | sha1sum)" = "$$(cat "${DIGEST_DIR}.digest")" ] && echo "[ Valid ] ${DIGEST_DIR}.digest" || echo "[*ERROR*] ${DIGEST_DIR}.digest"

# gpg ---------------------------------------------------------

.PHONY: run-gpg-sign
# Create detached GPG signatures for all files in the selected model.
run-gpg-sign:
	@echo "GPG sign individual files for ${MODEL} into ${GPG_DIR}" && \
	mkdir -p "${GPG_DIR}/${MODEL}" && \
	cd "./.cache/huggingface/hub/" && \
	find "${MODEL}" -type f | while read file; do \
		sig_file="${GPG_DIR}/$$file.sig"; \
		mkdir -p "$$(dirname "$$sig_file")" && \
		echo "Signing: $$file" && \
		gpg --output "$$sig_file" --yes --detach-sign "$$file"; \
	done

.PHONY: run-gpg-verify
# Verify detached GPG signatures for all files in the selected model.
run-gpg-verify:
	@echo "GPG verify individual files for ${MODEL} into ${GPG_DIR}" && \
	cd "./.cache/huggingface/hub/" && \
	find "${MODEL}" -type f | while read file; do \
		sig_file="${GPG_DIR}/$$file.sig"; \
		[ -f "$$sig_file" ] || { echo "[*ERROR*] Missing signature: $$sig_file"; exit 1; }; \
		echo "Verifying: $$file" && \
		gpg --verify "$$sig_file" "$$file"; \
	done

# cyclonedx ---------------------------------------------------------

.PHONY: run-mlbom-generate
# Generate a CycloneDX ML-BOM XML from files under the model cache.
run-mlbom-generate:
	mkdir -p "mlbom/${MODEL}"
	cyclonedx add files --no-input \
		--output-format xml \
		--exclude "/.git/**" \
		--base-path ".cache/huggingface/hub/" \
		--output-file "mlbom/${MODEL}/mlbom.xml"

.PHONY: run-mlbom-analyze
# Analyze the generated ML-BOM and report version relationships.
run-mlbom-analyze:
	cyclonedx analyze --input-format xml \
		--input-file mlbom/${MODEL}/mlbom.xml \
		--multiple-component-versions

.PHONY: run-mlbom-validate
# Validate the generated ML-BOM and fail if schema issues are found.
run-mlbom-validate:
	cyclonedx validate --input-format xml \
		--input-file "mlbom/${MODEL}/mlbom.xml" \
		--fail-on-errors

.PHONY: mlbom-keygen
# Generate ML-BOM signing keypair files in ssh and pubkeys locations.
mlbom-keygen:
	cyclonedx keygen \
		--private-key-file "$$HOME/.ssh/mlbom.key" \
		--public-key-file "pubkeys/mlbom.pub"

.PHONY: run-mlbom-sign
# Copy current ML-BOM as reference and sign it with the private key.
run-mlbom-sign:
	@[ -f "$$HOME/.ssh/mlbom.key" ] || { echo "[*ERROR*] Requires private key at $$HOME/.ssh/mlbom.key"; exit 1; };
	@echo "Copy a reference of unsigned mlbom for later comparison"
	cp "mlbom/${MODEL}/mlbom.xml" "mlbom/${MODEL}/mlbom-reference.xml"
	cyclonedx sign bom "mlbom/${MODEL}/mlbom.xml" \
		--key-file "$$HOME/.ssh/mlbom.key"

.PHONY: run-mlbom-verify-sign
# Verify signatures in the reference ML-BOM using the public key.
run-mlbom-verify-sign:
	@[ -f "./pubkeys/mlbom.pub" ] || { echo "[*ERROR*] Requires public key at ./pubkeys/mlbom.pub"; exit 1; };
	cyclonedx verify all "mlbom/${MODEL}/mlbom.xml" \
		--key-file "./pubkeys/mlbom.pub"

.PHONY: run-mlbom-diff
# Compare the generated ML-BOM with the saved reference ML-BOM.
run-mlbom-diff:
	diff "mlbom/${MODEL}/mlbom-reference.xml" "mlbom/${MODEL}/mlbom.xml"

# cyclonedx container ---------------------------------------------------------

.PHONY: crun-mlbom-generate
# Generate a CycloneDX ML-BOM XML from files under the model cache using container.
crun-mlbom-generate:
	mkdir -p "mlbom/${MODEL}"
	docker run --platform linux/amd64 --rm -v "$$(pwd)":/workspace -w /workspace -u $$(id -u):$$(id -g) \
		docker.io/cyclonedx/cyclonedx-cli:0.30.0 add files --no-input \
		--output-format xml \
		--exclude "/.git/**" \
		--base-path ".cache/huggingface/hub/" \
		--output-file "mlbom/${MODEL}/mlbom.xml"

.PHONY: cmlbom-keygen
# Generate ML-BOM signing keypair files in ssh and pubkeys locations using container.
cmlbom-keygen:
	docker run --platform linux/amd64 --rm -v "$$(pwd)":/workspace -w /workspace -u $$(id -u):$$(id -g) \
		-v "$$HOME/.ssh":"$$HOME/.ssh" \
		docker.io/cyclonedx/cyclonedx-cli:0.30.0 keygen \
		--private-key-file "$$HOME/.ssh/mlbom.key" \
		--public-key-file "pubkeys/mlbom.pub"

.PHONY: crun-mlbom-analyze
# Analyze the generated ML-BOM and report version relationships using container.
crun-mlbom-analyze:
	docker run --platform linux/amd64 --rm -v "$$(pwd)":/workspace -w /workspace -u $$(id -u):$$(id -g) \
		cyclonedx/cyclonedx-cli:0.30.0 analyze --input-format xml \
		--input-file "mlbom/${MODEL}/mlbom.xml" \
		--multiple-component-versions

.PHONY: crun-mlbom-validate
# Validate the generated ML-BOM and fail if schema issues are found using container.
crun-mlbom-validate:
	docker run --platform linux/amd64 --rm -v "$$(pwd)":/workspace -w /workspace -u $$(id -u):$$(id -g) \
		cyclonedx/cyclonedx-cli:0.30.0 validate --input-format xml \
		--input-file "mlbom/${MODEL}/mlbom.xml" \
		--fail-on-errors

.PHONY: crun-mlbom-sign
# Copy current ML-BOM as reference and sign it with the private key using container.
crun-mlbom-sign:
	@[ -f "$$HOME/.ssh/mlbom.key" ] || { echo "[*ERROR*] Requires private key at $$HOME/.ssh/mlbom.key"; exit 1; };
	cp "mlbom/${MODEL}/mlbom.xml" "mlbom/${MODEL}/mlbom-reference.xml"
	docker run --platform linux/amd64 --rm -v "$$(pwd)":/workspace -w /workspace -u $$(id -u):$$(id -g) \
		-v "$$HOME/.ssh/mlbom.key":"$$HOME/.ssh/mlbom.key":ro \
		cyclonedx/cyclonedx-cli:0.30.0 sign bom "mlbom/${MODEL}/mlbom.xml" \
		--key-file "$$HOME/.ssh/mlbom.key"

.PHONY: crun-mlbom-verify-sign
# Verify signatures in the ML-BOM using the public key via container.
crun-mlbom-verify-sign:
	@[ -f "./pubkeys/mlbom.pub" ] || { echo "[*ERROR*] Requires public key at ./pubkeys/mlbom.pub"; exit 1; };
	@[ -f "mlbom/${MODEL}/mlbom.xml" ] || { echo "[*ERROR*] Requires ML-BOM at mlbom/${MODEL}/mlbom.xml"; exit 1; };
	docker run --platform linux/amd64 --rm -v "$$(pwd)":/workspace -w /workspace -u $$(id -u):$$(id -g) \
		cyclonedx/cyclonedx-cli:0.30.0 verify all "mlbom/${MODEL}/mlbom.xml" \
		--key-file "./pubkeys/mlbom.pub"

# Cosign model ---------------------------------------------------------

.PHONY: cosign-generate-key-pair
# Generate a Cosign keypair and move keys to ssh and pubkeys paths.
cosign-generate-key-pair:
	cosign generate-key-pair
	mv cosign.key "$$HOME/.ssh"
	mv cosign.pub "./pubkeys"

.PHONY: run-cosign-sign
# Create Cosign bundle signatures for each model file using a local key.
run-cosign-sign:
	OUTPUT_DIR="$(shell pwd)/cosign" && \
	mkdir -p "$$OUTPUT_DIR/${MODEL}" && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f | while read file; do \
		sig_file="$$OUTPUT_DIR/$$file.sig"; \
		mkdir -p "$$(dirname "$$sig_file")" && \
		echo "Signing: $$file" && \
		cosign sign-blob --key "$$HOME/.ssh/cosign.key" --bundle "$$sig_file" "$$file" --yes || exit 1; \
	done

.PHONY: run-cosign-verify
# Verify Cosign blob signatures for each model file with a public key.
run-cosign-verify:
	OUTPUT_DIR="$(shell pwd)/cosign" && \
	PUBKEY="$(shell pwd)/pubkeys/cosign.pub" && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f | while read file; do \
		sig_file="$$OUTPUT_DIR/$$file.sig"; \
		[ -f "$$sig_file" ] || { echo "[*ERROR*] Missing signature: $$sig_file"; exit 1; }; \
		echo "Verifying: $$file" && \
		cosign verify-blob --key "$$PUBKEY" --bundle "$$sig_file" "$$file" || exit 1; \
	done

# Cosign container ---------------------------------------------------------

.PHONY: run-container-sign-keyless
# Sign the pulled container image using keyless Sigstore identity flow.
run-container-sign-keyless: container-pull
	@echo "Siging keyless container image ${CONTAINER_IMAGE}@${CONTAINER_SHA}"
	cosign sign ${CONTAINER_IMAGE}@${CONTAINER_SHA}

.PHONY: run-container-verify-keyless
# Verify keyless signature claims on the container image.
run-container-verify-keyless: container-pull
	@echo "Verifying keyless signature for container image ${CONTAINER_IMAGE}@${CONTAINER_SHA}"
	cosign verify \
		--certificate-identity ${SIGNER_ID} \
		--certificate-oidc-issuer ${SIGNER_OIDC} \
		${CONTAINER_IMAGE}@${CONTAINER_SHA}

.PHONY: run-container-sign-key
# Sign the pulled container image with a local Cosign private key.
run-container-sign-key: container-pull
	@echo "Siging container image ${CONTAINER_IMAGE}@${CONTAINER_SHA}"
	cosign sign --key $$HOME/.ssh/cosign.key \
		${CONTAINER_IMAGE}@${CONTAINER_SHA}

.PHONY: run-container-verify-key
# Verify a key-based Cosign signature on the container image.
run-container-verify-key: container-pull
	@echo "Verifying key-based signature for container image ${CONTAINER_IMAGE}@${CONTAINER_SHA}"
	cosign verify \
		--key ./pubkeys/cosign.pub \
		${CONTAINER_IMAGE}@${CONTAINER_SHA}

# Cosign container based targets ---------------------------------------------------------

.PHONY: cgen-cosign-key-pair
# Generate a Cosign keypair using container and move keys to ssh and pubkeys paths.
cgen-cosign-key-pair:
	docker run --platform linux/amd64 --rm -it \
		-u $$(id -u):$$(id -g) \
		-v "$$(pwd)":/workspace -w /workspace 
		dhi.io/cosign:3 generate-key-pair
	mv cosign.key "$$HOME/.ssh"
	mv cosign.pub "./pubkeys"

.PHONY: ccosign-sign
# Create Cosign bundle signatures for each model file using container and local key.
ccosign-sign:
	@read -s -p "Enter password for cosign key: " COSIGN_PASSWORD; \
	export COSIGN_PASSWORD; \
	OUTPUT_DIR="$(shell pwd)/cosign" && \
	mkdir -p $$OUTPUT_DIR/${MODEL} && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f | while read file; do \
		sig_file="$$OUTPUT_DIR/$$file.sig"; \
		mkdir -p "$$(dirname "$$sig_file")" && \
		echo -e "Signing: $$file\nPwd: $$(pwd)\nSig file: $$sig_file" && \
		ls -la $$file && \
		docker run --platform linux/amd64 --rm \
			-u $$(id -u):$$(id -g) \
			-v "$$(pwd)":/workspace -w /workspace  \
			-v "$$HOME/.ssh/cosign.key":"$$HOME/.ssh/cosign.key":ro \
			-v "$$HOME/.sigstore:/.sigstore" \
			-e COSIGN_PASSWORD="$$COSIGN_PASSWORD" \
			dhi.io/cosign:3 sign-blob --key "$$HOME/.ssh/cosign.key" "$$file" --yes > "test.sig" || exit 1; \
	done

.PHONY: ccosign-verify
# Verify Cosign blob signatures for each model file using container with public key.
ccosign-verify:
	OUTPUT_DIR="$(shell pwd)/cosign" && \
	PUBKEY="$(shell pwd)/pubkeys/cosign.pub" && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f | while read file; do \
		sig_file="$$OUTPUT_DIR/$$file.sig"; \
		[ -f "$$sig_file" ] || { echo "[*ERROR*] Missing signature: $$sig_file"; exit 1; }; \
		echo "Verifying: $$file" && \
		docker run --platform linux/amd64 --rm \
			-u $$(id -u):$$(id -g) \
			-v "$$(pwd)":/workspace -w /workspace \
			dhi.io/cosign:3 verify-blob --key "$$PUBKEY" --signature "$$sig_file" "$$file" || exit 1; \
	done

.PHONY: crun-container-sign-key
# Sign the pulled container image using container with Cosign local key.
crun-container-sign-key: container-pull
	@echo "Signing container image ${CONTAINER_IMAGE}@${CONTAINER_SHA} using container"
	docker run --platform linux/amd64 --rm -v "$$(pwd)":/workspace -w /workspace -u $$(id -u):$$(id -g) \
		-v "$$HOME/.ssh/cosign.key":"$$HOME/.ssh/cosign.key":ro \
		dhi.io/cosign:3 sign --key "$$HOME/.ssh/cosign.key" \
		${CONTAINER_IMAGE}@${CONTAINER_SHA}

.PHONY: crun-container-verify-key
# Verify a key-based Cosign signature on the container image using container.
crun-container-verify-key: container-pull
	@echo "Verifying key-based signature for container image ${CONTAINER_IMAGE}@${CONTAINER_SHA} using container"
	docker run --platform linux/amd64 --rm -v "$$(pwd)":/workspace -w /workspace -u $$(id -u):$$(id -g) \
		dhi.io/cosign:3 verify \
		--key "./pubkeys/cosign.pub" \
		${CONTAINER_IMAGE}@${CONTAINER_SHA}

# Utilities ---------------------------------------------------------

.PHONY: container-pull
# Pull the configured container image tag from the remote registry.
container-pull:
	docker pull --platform linux/amd64 ${CONTAINER_IMAGE}:${CONTAINER_TAG}

.PHONY: container-sha
# Print the full image digest SHA for the pulled container image tag.
container-sha:
	docker images --no-trunc --quiet ${CONTAINER_IMAGE}:${CONTAINER_TAG}

# download ----------------------------------------------------------------

.PHONY: download
# Download model files using the HTTPS Git transport by default.
download: download-local-git-https

.PHONY: download-local-git-ssh
# Clone the model repository over SSH and then pin to the commit.
download-local-git-ssh:
	@make -s git-prepare
	git clone --depth 1 git@hf.co:${MODEL} "${MODEL_DIR}"
	@make -s git-finish

.PHONY: download-local-git-https
# Clone the model repository over HTTPS and then pin to the commit.
download-local-git-https:
	@make -s git-prepare
	git clone --depth 1 https://huggingface.co/${MODEL} "${MODEL_DIR}"
	@make -s git-finish

.PHONY: git-prepare
# Prepare local git-lfs state and remove any previous model directory.
git-prepare:
	@echo "Cloning ${MODEL} commit ${COMMIT}"
	git lfs install
	rm -rf "${MODEL_DIR}"

.PHONY: git-finish
# Checkout the pinned commit and remove git metadata from model dir.
git-finish:
	cd "${MODEL_DIR}" && \
	git fetch --depth 1 origin "${COMMIT}" && \
	git -c advice.detachedHead=false checkout "${COMMIT}"
	rm -rf "${MODEL_DIR}"/.git

#  ----------------------------------------------------------------

.PHONY: container-run
# Start an interactive container with this attestation directory mounted.
container-run:
	${RUNSUDO} docker run --platform linux/amd64 -it \
		-v "$$(pwd)/../attestation":/home/user/attestation \
		-u $$(id -u):$$(id -g) \
		quay.io/vicenteherrera/python-dev-shell:3.11.7 \
		sh -c "cd attestation && make help && /bin/bash"

.PHONY: size
# Display total disk usage for cached Hugging Face model data.
size:
	@echo "Size of models in ./.cache/huggingface/"
	@du -sh "./.cache/huggingface/ ||:


