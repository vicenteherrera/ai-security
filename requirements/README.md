# Requirements

Prerequisites and installation guides for the tools used throughout the exercises.

---

## Python

### macOS

Python 3 is included with Xcode Command Line Tools, or install via Homebrew:

```bash
brew install python
```

### Linux (Debian/Ubuntu) / Windows (WSL2)

```bash
sudo apt update && sudo apt install -y python3 python3-pip python3-venv
```

---

## Poetry

[Poetry](https://python-poetry.org/) is used for Python dependency management.

### macOS / Linux (Debian/Ubuntu) / Windows (WSL2)

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

Add Poetry to your PATH (if not done automatically):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## uv

[uv](https://docs.astral.sh/uv/) is a fast Python package and project manager that can replace pip, venv, and Poetry. It automatically creates virtual environments when running `uv sync` or `uv run`.

### macOS / Linux (Debian/Ubuntu) / Windows (WSL2)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Or with Homebrew (macOS/Linux):

```bash
brew install uv
```

Verify the installation:

```bash
uv --version
```

---

## Docker

### macOS

Install [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/).

Alternatively, using Homebrew:

```bash
brew install --cask docker
```

### Linux (Debian/Ubuntu) / Windows (WSL2)

On Windows, install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/) with the WSL2 backend. On Linux:

```bash
# Add Docker's official GPG key and repository
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

See the [official docs](https://docs.docker.com/engine/install/) for other distributions.

---

## Cosign

[Cosign](https://github.com/sigstore/cosign) is used for signing and verifying container images and artifacts.

Install it using the provided script:

```bash
./install-cosign.sh
```

The script auto-detects your OS (Linux, macOS, Windows/MSYS) and architecture, then downloads the latest release from GitHub.

---

## CycloneDX CLI

[CycloneDX CLI](https://github.com/CycloneDX/cyclonedx-cli) is used for generating and validating Software Bill of Materials (SBOM) in CycloneDX format.

Install it using the provided script:

```bash
./install-cyclonedx-cli.sh
```

The script auto-detects your OS and architecture, then downloads the latest release from GitHub.

---

## Make

### macOS

Included with Xcode Command Line Tools:

```bash
xcode-select --install
```

### Linux (Debian/Ubuntu) / Windows (WSL2)

```bash
sudo apt update && sudo apt install -y make
```

---

## jq

[jq](https://jqlang.github.io/jq/) is a command-line JSON processor used in the vulnerability scanning exercises.

### macOS

```bash
brew install jq
```

### Linux (Debian/Ubuntu) / Windows (WSL2)

```bash
sudo apt update && sudo apt install -y jq
```
