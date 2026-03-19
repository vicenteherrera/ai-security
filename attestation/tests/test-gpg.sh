#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

cd "$(dirname "$0")/.."

echo "========================================="
echo "Testing GPG Based Targets of Makefile"
echo "========================================="

echo -e "\n---> 1. Downloading fresh model (make download)"
set +e
make download
MAKE_EXIT=$?
set -e
if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make download exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

echo -e "\n---> 2. Generating GPG signatures (make run-gpg-sign)"
set +e
make run-gpg-sign
MAKE_EXIT=$?
set -e
if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make run-gpg-sign exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

echo -e "\n---> 3. Validating GPG signatures (make run-gpg-verify) - Expecting Success"
# We turn off exit on error temporarily so we can check the exit code
set +e
VERIFY_OUT=$(make run-gpg-verify 2>&1)
MAKE_EXIT=$?
set -e
echo "$VERIFY_OUT"

if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make run-gpg-verify exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

if echo "$VERIFY_OUT" | grep -iq "BAD signature"; then
    echo -e "\n[FAIL] Found BAD signature when it should have succeeded."
    exit 1
else
    echo -e "\n[PASS] GPG validation passed correctly."
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

echo -e "\n---> 5. Validating GPG signatures again (make run-gpg-verify) - Expecting Error"
set +e
VERIFY_OUT_TAMPER=$(make run-gpg-verify 2>&1)
MAKE_EXIT=$?
set -e

echo "$VERIFY_OUT_TAMPER"

if [ $MAKE_EXIT -ne 0 ]; then
    echo -e "\n[FAIL] make run-gpg-verify exited with $MAKE_EXIT (expected 0)"
    exit 1
fi

if echo "$VERIFY_OUT_TAMPER" | grep -iq "BAD signature"; then
    echo -e "\n[PASS] Tampering was successfully detected by GPG (BAD signature found)."
else
    echo -e "\n[FAIL] Validation passed unexpectedly after tampering! It should have detected the tampering."
    exit 1
fi

echo -e "\n========================================="
echo "All GPG tests completed successfully!"
echo "========================================="
