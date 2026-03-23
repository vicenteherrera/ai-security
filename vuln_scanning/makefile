# Vulnerability Scanning with Trivy — exercise targets

RESULTS_JSON := results.json

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##"}; {printf "  %-18s %s\n", $$1, $$2}'

.PHONY: scan
# Full vulnerability scan of python:3.11
scan: ## Scan python:3.11 for all vulnerabilities
	trivy image python:3.11

.PHONY: filter-severity
# Scan node:20 filtered to HIGH and CRITICAL severities only
filter-severity: ## Scan node:20 showing only HIGH and CRITICAL
	trivy image --severity HIGH,CRITICAL node:20

.PHONY: filter-critical
# Scan node:20 filtered to CRITICAL severity only
filter-critical: ## Scan node:20 showing only CRITICAL
	trivy image --severity CRITICAL node:20

.PHONY: filter-slim
# Scan node:20-slim filtered to HIGH and CRITICAL severities
filter-slim: ## Scan node:20-slim showing only HIGH and CRITICAL
	trivy image --severity HIGH,CRITICAL node:20-slim

.PHONY: compare-variants
# Scan python:3.11 full, slim, and alpine to compare attack surface
compare-variants: ## Scan python:3.11, python:3.11-slim, and python:3.11-alpine
	trivy image python:3.11
	@echo "---"
	trivy image python:3.11-slim
	@echo "---"
	trivy image python:3.11-alpine

.PHONY: json-report
# Export nginx:latest scan results to a JSON file
json-report: ## Generate a JSON vulnerability report for nginx:latest
	trivy image --format json --output $(RESULTS_JSON) nginx:latest
	@echo "Report written to $(RESULTS_JSON)"

.PHONY: count-vulns
# Count total vulnerabilities found in the JSON report
count-vulns: $(RESULTS_JSON) ## Count total vulnerabilities in the JSON report
	jq '[.Results[].Vulnerabilities[]?] | length' $(RESULTS_JSON)

.PHONY: list-critical
# Extract CRITICAL CVE IDs from the JSON report
list-critical: $(RESULTS_JSON) ## List CRITICAL CVE IDs from the JSON report
	jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL") | .VulnerabilityID]' $(RESULTS_JSON)

.PHONY: clean
# Delete generated report files
clean: ## Remove generated report files
	rm -f $(RESULTS_JSON)

# ---------------------------------------------------------------------------
# Container-based targets (trivy via Docker)
# ---------------------------------------------------------------------------

TRIVY_CMD := docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy

.PHONY: cscan
# Full vulnerability scan of python:3.11 (container)
cscan: ## [container] Scan python:3.11 for all vulnerabilities
	$(TRIVY_CMD) image python:3.11

.PHONY: cfilter-severity
# Scan node:20 filtered to HIGH and CRITICAL severities only (container)
cfilter-severity: ## [container] Scan node:20 showing only HIGH and CRITICAL
	$(TRIVY_CMD) image --severity HIGH,CRITICAL node:20

.PHONY: cfilter-critical
# Scan node:20 filtered to CRITICAL severity only (container)
cfilter-critical: ## [container] Scan node:20 showing only CRITICAL
	$(TRIVY_CMD) image --severity CRITICAL node:20

.PHONY: cfilter-slim
# Scan node:20-slim filtered to HIGH and CRITICAL severities (container)
cfilter-slim: ## [container] Scan node:20-slim showing only HIGH and CRITICAL
	$(TRIVY_CMD) image --severity HIGH,CRITICAL node:20-slim

.PHONY: ccompare-variants
# Scan python:3.11 full, slim, and alpine to compare attack surface (container)
ccompare-variants: ## [container] Scan python:3.11, python:3.11-slim, and python:3.11-alpine
	$(TRIVY_CMD) image python:3.11
	@echo "---"
	$(TRIVY_CMD) image python:3.11-slim
	@echo "---"
	$(TRIVY_CMD) image python:3.11-alpine

.PHONY: cjson-report
# Export nginx:latest scan results to a JSON file (container)
cjson-report: ## [container] Generate a JSON vulnerability report for nginx:latest
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --format json nginx:latest > $(RESULTS_JSON)
	@echo "Report written to $(RESULTS_JSON)"

.PHONY: ccount-vulns
# Count total vulnerabilities found in the JSON report (container)
ccount-vulns: $(RESULTS_JSON) ## [container] Count total vulnerabilities in the JSON report
	jq '[.Results[].Vulnerabilities[]?] | length' $(RESULTS_JSON)

.PHONY: clist-critical
# Extract CRITICAL CVE IDs from the JSON report (container)
clist-critical: $(RESULTS_JSON) ## [container] List CRITICAL CVE IDs from the JSON report
	jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL") | .VulnerabilityID]' $(RESULTS_JSON)
