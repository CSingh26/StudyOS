#!/usr/bin/env bash
set -euo pipefail

printf "==> Generating Xcode workspace with Tuist\n"

tuist generate
