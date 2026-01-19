#!/usr/bin/env bash
set -euo pipefail

printf "==> StudyOS bootstrap\n"

if ! command -v tuist >/dev/null 2>&1; then
  printf "Tuist not found. Installing via Homebrew...\n"
  if ! command -v brew >/dev/null 2>&1; then
    printf "Homebrew is required. Please install Homebrew first.\n" >&2
    exit 1
  fi
  brew update
  brew install tuist
fi

printf "Tuist version: %s\n" "$(tuist version)"
