.PHONY: help
# Print available targets with short descriptions
help:
	@awk 'BEGIN {FS=":"} /^# / {desc=substr($$0,3)} /^[a-zA-Z0-9_-]+:/ {if (desc != "") {printf "%-12s %s\n", $$1, desc; desc=""}}' $(MAKEFILE_LIST)

.PHONY: setup-env
# Copy example.env and generate random secrets in .env
setup-env:
	@set -e; \
	cp example.env .env; \
	SECRET1="$$(openssl rand -hex 32)"; \
	SECRET2="$$(openssl rand -hex 32)"; \
	SECRET3="$$(openssl rand -hex 32)"; \
	SECRET1="$$SECRET1" SECRET2="$$SECRET2" SECRET3="$$SECRET3" \
	perl -i -pe 's/your-random-secret-1/$$ENV{SECRET1}/g; s/your-random-secret-2/$$ENV{SECRET2}/g; s/your-random-secret-3/$$ENV{SECRET3}/g' .env; \
	echo "Generated .env with randomized secrets."

.PHONY: docker-up
# Start Threat Dragon services in detached mode
docker-up:
	docker compose -f docker-compose.yaml up -d
