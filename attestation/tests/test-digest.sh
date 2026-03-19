#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

cd "$(dirname "$0")/.."

echo "========================================="
echo "Testing Digest Based Targets of Makefile"
echo "========================================="

echo -e "\n---> 1. Downloading model (make download)"
set +e
make download
MAKE_EXIT=$?
set -e
if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make download exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

echo -e "\n---> 2. Generating digests (make run-digest-generate)"
set +e
make run-digest-generate
MAKE_EXIT=$?
set -e
if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make run-digest-generate exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

echo -e "\n---> 3. Validating digests (make run-digest-validate) - Expecting Success"
set +e
VALIDATE_OUT=$(make run-digest-validate 2>&1)
MAKE_EXIT=$?
set -e
echo "$VALIDATE_OUT"

if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make run-digest-validate exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

if echo "$VALIDATE_OUT" | grep -Fq "[*ERROR*]"; then
    echo -e "\n[FAIL] Validation failed when it should have succeeded."
    exit 1
else
    echo -e "\n[PASS] Validation passed correctly."
fi

echo -e "\n---> 4. Tampering with model (make run-tamper-model)"
set +e
make run-tamper-model
MAKE_EXIT=$?
set -e
if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make run-tamper-model exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

echo -e "\n---> 5. Validating digests again (make run-digest-validate) - Expecting Error"
set +e
VALIDATE_OUT_TAMPER=$(make run-digest-validate 2>&1)
MAKE_EXIT=$?
set -e
echo "$VALIDATE_OUT_TAMPER"

if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make run-digest-validate exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

if echo "$VALIDATE_OUT_TAMPER" | grep -Fq "[*ERROR*]"; then
    echo -e "\n[PASS] Tampering was successfully detected."
else
    echo -e "\n[FAIL] Validation passed unexpectedly after tampering! It should have detected the tampering."
    exit 1
fi

echo -e "\n========================================="
echo "All digest tests completed successfully!"
echo "========================================="
