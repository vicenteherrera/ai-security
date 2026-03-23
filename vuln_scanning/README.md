# Vulnerability Scanning with Trivy

[Trivy](https://github.com/aquasecurity/trivy) is an open-source vulnerability scanner for container images, file systems, and Git repositories. These exercises walk through basic container image scanning workflows.

## Prerequisites

Install Trivy (macOS):

```bash
brew install trivy
```

Or run it directly via Docker (no install needed):

```bash
docker run --rm aquasec/trivy image <image-name>
```

---

## Exercise 1 — Scan an Official Image for Known Vulnerabilities

Scan the `python:3.11` image and review the vulnerability report.

```bash
trivy image python:3.11
```

**Tasks:**

1. Run the command above and examine the output table.
2. Identify how many vulnerabilities are reported at each severity level (CRITICAL, HIGH, MEDIUM, LOW).
3. Pick one CRITICAL or HIGH vulnerability and look up its CVE ID on <https://nvd.nist.gov/> to understand the affected component.

---

## Exercise 2 — Filter Results by Severity

Scan the `node:20` image but only show HIGH and CRITICAL vulnerabilities to reduce noise.

```bash
trivy image --severity HIGH,CRITICAL node:20
```

**Tasks:**

1. Compare the output length to a full scan (`trivy image node:20`).
2. Re-run the scan filtering only CRITICAL vulnerabilities. How many remain?
3. Try the same filters against the slim variant `node:20-slim` and compare the number of findings.

---

## Exercise 3 — Compare Base-Image Variants

Evaluate how the choice of base image affects the vulnerability surface by scanning three variants of the same runtime.

```bash
trivy image python:3.11
trivy image python:3.11-slim
trivy image python:3.11-alpine
```

**Tasks:**

1. Record the total vulnerability count for each variant.
2. Note the image size difference (use `docker images` after pulling them).
3. Explain why the Alpine-based image typically has fewer vulnerabilities.

---

## Exercise 4 — Generate a JSON Report and Inspect It

Export Trivy results to a structured JSON file for programmatic analysis.

```bash
trivy image --format json --output results.json nginx:latest
```

**Tasks:**

1. Open `results.json` and locate the `Vulnerabilities` array inside the first `Result`.
2. Use `jq` to count the total number of vulnerabilities:
   ```bash
   jq '[.Results[].Vulnerabilities[]?] | length' results.json
   ```
3. Use `jq` to list only the CVE IDs rated CRITICAL:
   ```bash
   jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL") | .VulnerabilityID]' results.json
   ```
4. Clean up the report when done:
   ```bash
   rm results.json
   ```
