#!/usr/bin/env bash

# Exit on any error
set -e

echo "Starting cosign installation..."

# Determine OS
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Map OS name to cosign release format
if [ "$OS" = "darwin" ]; then
    OS="darwin"
elif [ "$OS" = "linux" ]; then
    OS="linux"
elif [[ "$OS" == "mingw"* ]] || [[ "$OS" == "msys"* ]] || [[ "$OS" == "cygwin"* ]]; then
    OS="windows"
else
    echo "Error: Unsupported OS: $OS"
    exit 1
fi

# Map Architecture name to cosign release format
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "arm" ]; then
    ARCH="arm"
elif [ "$OS" = "windows" ] && [[ "$ARCH" == *"86"* ]]; then
    ARCH="amd64"
else
    echo "Error: Unsupported Architecture: $ARCH"
    exit 1
fi

# Construct expected asset filename based on current OS and Architecture
if [ "$OS" = "windows" ]; then
    ASSET_NAME="cosign-${OS}-${ARCH}.exe"
else
    ASSET_NAME="cosign-${OS}-${ARCH}"
fi

echo "Detected Platform : $OS"
echo "Detected Arch     : $ARCH"
echo "Target Binary     : $ASSET_NAME"

# Fetch latest release data from GitHub API
echo "Fetching latest release information..."
LATEST_RELEASE_URL="https://api.github.com/repos/sigstore/cosign/releases/latest"
# Parse download URL matching our asset name
DOWNLOAD_URL=$(curl -sL "$LATEST_RELEASE_URL" | grep -o "https://[^\"]*releases/download/[^\"]*/$ASSET_NAME" | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find a matching download URL for asset: $ASSET_NAME"
    echo "Please check https://github.com/sigstore/cosign/releases/latest"
    exit 1
fi

echo "Downloading from: $DOWNLOAD_URL"

# Create a temporary directory for download
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
pushd "$TMP_DIR" > /dev/null

# Download the file
curl -sL -o "$ASSET_NAME" "$DOWNLOAD_URL"

# For cosign, releases are straight binaries
BIN_FILE="$ASSET_NAME"

# Make the file executable for Unix systems
if [ "$OS" != "windows" ]; then
    chmod +x "$BIN_FILE"
fi

# Determine final destination
INSTALL_DIR="/usr/local/bin"
FINAL_BIN_NAME="cosign"
if [ "$OS" = "windows" ]; then
    FINAL_BIN_NAME="cosign.exe"
    # Fallback to user bin if running git bash / msys on Windows
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
fi

echo "Attempting to install $FINAL_BIN_NAME to $INSTALL_DIR..."

popd > /dev/null

if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP_DIR/$BIN_FILE" "$INSTALL_DIR/$FINAL_BIN_NAME"
    echo "Successfully installed to $INSTALL_DIR/$FINAL_BIN_NAME"
else
    echo "Installation directory $INSTALL_DIR requires elevated permissions."
    echo "Attempting to move the binary with sudo..."
    if command -v sudo >/dev/null 2>&1; then
        sudo mv "$TMP_DIR/$BIN_FILE" "$INSTALL_DIR/$FINAL_BIN_NAME"
        echo "Successfully installed to $INSTALL_DIR/$FINAL_BIN_NAME"
    else
        echo "Elevated permissions (sudo) not available."
        
        # Fallback 1: ~/.local/bin
        USER_BIN="$HOME/.local/bin"
        echo "Trying to install to $USER_BIN instead..."
        mkdir -p "$USER_BIN"
        mv "$TMP_DIR/$BIN_FILE" "$USER_BIN/$FINAL_BIN_NAME"
        
        echo "=========================================================="
        echo "The binary was installed to: $USER_BIN/$FINAL_BIN_NAME"
        if ! command -v cosign >/dev/null 2>&1; then
            echo "PLEASE ADD IT TO YOUR PATH MANUALLY by adding this to your shell profile (~/.bashrc, ~/.zshrc, etc):"
            echo "export PATH=\"\$PATH:$USER_BIN\""
        fi
        echo "=========================================================="
        exit 0
    fi
fi

if command -v cosign >/dev/null 2>&1; then
    echo "Installation complete! Verifying version:"
    cosign version
else
    echo "=========================================================="
    echo " cosign binary was installed to $INSTALL_DIR,"
    echo " but $INSTALL_DIR is not in your PATH."
    echo " Please add it to your PATH manually:"
    echo " export PATH=\"\$PATH:$INSTALL_DIR\""
    echo "=========================================================="
fi
