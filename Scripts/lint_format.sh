#!/usr/bin/env bash
set -euo pipefail

printf "==> Formatting Swift code\n"

if command -v swift-format >/dev/null 2>&1; then
  swift-format format --recursive --in-place Sources Tests
  printf "swift-format completed.\n"
else
  printf "swift-format not found. Install with: brew install swift-format\n"
  printf "Skipping formatting.\n"
fi
