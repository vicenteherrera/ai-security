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
	@echo "# Sign the generated CycloneDX BOM file with a private key"
	@echo "make run-mlbom-reference-sign"
	@echo "# Verify the signature of the reference CycloneDX BOM file provided"
	@echo "make run-mlbom-reference-verify-sign"
	@echo "# Conventional diff the generated and signed reference CycloneDX BOM files"
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
	mkdir -p ${DIGEST_DIR}/${MODEL} && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f | while read file; do \
		digest_file="${DIGEST_DIR}/$$file.digest"; \
		mkdir -p "$$(dirname "$$digest_file")"; \
		sha1sum "$$file" | tee "$$digest_file"; \
	done
	@echo ""
	@echo "Calculating hash of global directory for ${MODEL}"
	@cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f \( -exec sha1sum "{}" \; \) | awk '{print $1}' | sort | sha1sum | tee "${DIGEST_DIR}.digest"
	

.PHONY: run-digest-validate
# Validate model files against stored per-file and global digest values.
run-digest-validate:
	@echo "Validating hash of individual files for ${MODEL} into ${DIGEST_DIR}" && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f -exec sh -c 'file="${DIGEST_DIR}/{}" && [ "$$(sha1sum {})" = "$$(cat "$$file.digest")" ] && echo "[ Valid ] $$file" || echo "[*ERROR*] $$file"' {} \; 
	@echo ""
	@echo "Validating hash of global directory for ${MODEL}"
	@cd "./.cache/huggingface/hub/" && \
	[ "$$(find ${MODEL} -type f \( -exec sha1sum "{}" \; \) | awk '{print $1}' | sort | sha1sum)" = "$$(cat "${DIGEST_DIR}.digest")" ] && echo "[ Valid ] ${DIGEST_DIR}.digest" || echo "[*ERROR*] ${DIGEST_DIR}.digest"

# gpg ---------------------------------------------------------

.PHONY: run-gpg-sign
# Create detached GPG signatures for all files in the selected model.
run-gpg-sign:
	@echo "GPG sign individual files for ${MODEL} into ${GPG_DIR}" && \
	mkdir -p ${GPG_DIR}/${MODEL} && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f | while read file; do \
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
	find ${MODEL} -type f | while read file; do \
		sig_file="${GPG_DIR}/$$file.sig"; \
		[ -f "$$sig_file" ] || { echo "[*ERROR*] Missing signature: $$sig_file"; exit 1; }; \
		echo "Verifying: $$file" && \
		gpg --verify "$$sig_file" "$$file"; \
	done

# cyclonedx ---------------------------------------------------------

.PHONY: run-mlbom-generate
# Generate a CycloneDX ML-BOM XML from files under the model cache.
run-mlbom-generate:
	mkdir -p mlbom/${MODEL}
	cyclonedx add files --no-input \
		--output-format xml \
		--exclude /.git/** \
		--base-path .cache/huggingface/hub/ \
		--output-file mlbom/${MODEL}/mlbom.xml

.PHONY: mlbom-keygen
# Generate ML-BOM signing keypair files in ssh and pubkeys locations.
mlbom-keygen:
	cyclonedx keygen \
		--private-key-file $$HOME/.ssh/mlbom.key \
		--public-key-file pubkeys/mlbom.pub

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
		--input-file mlbom/${MODEL}/mlbom.xml \
		--fail-on-errors

.PHONY: run-mlbom-reference-sign
# Copy current ML-BOM as reference and sign it with the private key.
run-mlbom-reference-sign:
	@[ -f "$$HOME/.ssh/mlbom.key" ] || { echo "[*ERROR*] Requires private key at $$HOME/.ssh/mlbom.key"; exit 1; };
	cp mlbom/${MODEL}/mlbom.xml mlbom/${MODEL}/mlbom-reference.xml
	cyclonedx sign bom mlbom/${MODEL}/mlbom.xml \
		--key-file $$HOME/.ssh/mlbom.key

.PHONY: run-mlbom-reference-verify-sign
# Verify signatures in the reference ML-BOM using the public key.
run-mlbom-reference-verify-sign:
	@[ -f "./pubkeys/mlbom.pub" ] || { echo "[*ERROR*] Requires public key at ./pubkeys/mlbom.pub"; exit 1; };
	cyclonedx verify all mlbom/${MODEL}/mlbom-reference.xml \
		--key-file ./pubkeys/mlbom.pub

.PHONY: run-mlbom-diff
# Compare the generated ML-BOM with the saved reference ML-BOM.
run-mlbom-diff:
	diff mlbom/${MODEL}/mlbom-reference.xml mlbom/${MODEL}/mlbom.xml

# Cosign model ---------------------------------------------------------

.PHONY: cosign-generate-key-pair
# Generate a Cosign keypair and move keys to ssh and pubkeys paths.
cosign-generate-key-pair:
	cosign generate-key-pair
	mv cosign.key $$HOME/.ssh
	mv cosign.pub ./pubkeys

.PHONY: run-cosign-sign
# Create Cosign blob signatures for each model file using a local key.
run-cosign-sign:
	export OUTPUT_DIR="$(shell pwd)/cosign" && \
	mkdir -p $$OUTPUT_DIR/${MODEL} && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f | while read file; do \
		sig_file="$$OUTPUT_DIR/$$file.sig"; \
		mkdir -p "$$(dirname "$$sig_file")" && \
		echo "Signing: $$file" && \
		COSIGN_PASSWORD="changeme" cosign sign-blob --key "$$HOME/.ssh/cosign.key" --output-signature "$$sig_file" "$$file" --yes || exit 1; \
	done

.PHONY: run-cosign-verify
# Verify Cosign blob signatures for each model file with a public key.
run-cosign-verify:
	export OUTPUT_DIR="$(shell pwd)/cosign" && \
	export PUBKEY="$(shell pwd)/pubkeys/cosign.pub" && \
	cd "./.cache/huggingface/hub/" && \
	find ${MODEL} -type f | while read file; do \
		sig_file="$$OUTPUT_DIR/$$file.sig"; \
		[ -f "$$sig_file" ] || { echo "[*ERROR*] Missing signature: $$sig_file"; exit 1; }; \
		echo "Verifying: $$file" && \
		cosign verify-blob --key "$$PUBKEY" --signature "$$sig_file" "$$file" || exit 1; \
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
	@echo "Verifying keyless signature for container image ${CONTAINER_IMAGE}@${CONTAINER_SHA}"
	cosign verify \
		--key cosign.pub \
		${CONTAINER_IMAGE}@${CONTAINER_SHA}

# Utilities ---------------------------------------------------------

.PHONY: container-pull
# Pull the configured container image tag from the remote registry.
container-pull:
	docker pull ${CONTAINER_IMAGE}:${CONTAINER_TAG}

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
	${RUNSUDO} docker run -it \
		-v "$$(pwd)/../attestation":/home/user/attestation \
		-u $$(id -u):$$(id -g) \
		quay.io/vicenteherrera/python-dev-shell:3.11.7 \
		sh -c "cd attestation && make help && /bin/bash"

.PHONY: size
# Display total disk usage for cached Hugging Face model data.
size:
	@echo "Size of models in ./.cache/huggingface/"
	@du -sh ./.cache/huggingface/ ||:


