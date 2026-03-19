#!/bin/bash

# Exit script if main directory changes fail
set -e

cd "$(dirname "$0")/.."

echo "========================================="
echo "Testing Local CycloneDX Targets of Makefile"
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
    
    if [ "$target" = "run-mlbom-diff" ] && [ $exit_code -eq 2 ]; then
        echo -e "\n[PASS] make $target (exit code 2 is expected)"
    elif [ $exit_code -ne 0 ]; then
        echo -e "\n[FAIL] make $target exited with $exit_code"
        FAILED_TARGETS+=("$target")
    else
        echo -e "\n[PASS] make $target"
    fi
}

echo -e "\n---> Setting up: Downloading model (make download)"
run_target "download"

# Test Local Targets
echo -e "\n=== Testing Local CycloneDX Targets ==="
run_target "run-mlbom-generate"
run_target "run-mlbom-analyze"
run_target "run-mlbom-validate"
run_target "mlbom-keygen"
run_target "run-mlbom-sign"
run_target "run-mlbom-verify-sign"
run_target "run-mlbom-diff"

echo -e "\n========================================="
echo "Local CycloneDX tests completed."
echo "========================================="

if [ ${#FAILED_TARGETS[@]} -eq 0 ]; then
    echo -e "\n[SUCCESS] All Local CycloneDX targets passed!"
    exit 0
else
    echo -e "\n[WARNING] The following targets failed:"
    for target in "${FAILED_TARGETS[@]}"; do
        echo "  - $target"
    done
    exit 1
fi
