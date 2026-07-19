#!/usr/bin/env bash
# Compiles the exposure-math models with the sanity tests and runs them.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
OUT_DIR="$(mktemp -d)"
trap 'rm -rf "$OUT_DIR"' EXIT

# swiftc only allows top-level statements in a file named main.swift
cp "$SCRIPT_DIR/exposure_math_tests.swift" "$OUT_DIR/main.swift"

swiftc \
  "$ROOT/TanCast/Models/FitzpatrickType.swift" \
  "$ROOT/TanCast/Models/SunExposureScore.swift" \
  "$OUT_DIR/main.swift" \
  -o "$OUT_DIR/exposure_tests"

"$OUT_DIR/exposure_tests"
