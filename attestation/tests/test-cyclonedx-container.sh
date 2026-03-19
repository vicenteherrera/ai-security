#!/bin/bash

# Exit script if main directory changes fail
set -e

cd "$(dirname "$0")/.."

echo "========================================="
echo "Testing Container CycloneDX Targets of Makefile"
echo "========================================="

# Helper array to store failed targets
FAILED_TARGETS=()

# Helper function to run a make target and record its success/failure
run_target() {
    local target=$1
    echo -e "\n---> Running: make $target"
    
    set +e
    make $target
    local exit_code=$?
    set -e
    
    if [ $exit_code -ne 0 ]; then
        echo -e "\n[FAIL] make $target exited with $exit_code"
        FAILED_TARGETS+=("$target")
    else
        echo -e "\n[PASS] make $target"
    fi
}

echo -e "\n---> Setting up: Downloading model (make download)"
run_target "download"

# Test Container Targets
echo -e "\n=== Testing Container CycloneDX Targets ==="
run_target "crun-mlbom-generate"
run_target "crun-mlbom-analyze"
run_target "crun-mlbom-validate"
run_target "cmlbom-keygen"
run_target "crun-mlbom-sign"
run_target "crun-mlbom-verify-sign"

echo -e "\n========================================="
echo "Container CycloneDX tests completed."
echo "========================================="

if [ ${#FAILED_TARGETS[@]} -eq 0 ]; then
    echo -e "\n[SUCCESS] All Container CycloneDX targets passed!"
    exit 0
else
    echo -e "\n[WARNING] The following targets failed:"
    for target in "${FAILED_TARGETS[@]}"; do
        echo "  - $target"
    done
    exit 1
fi
