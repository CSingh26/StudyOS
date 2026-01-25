#!/usr/bin/env bash
set -euo pipefail

printf "==> Running unit and UI tests\n"

xcodebuild test \
  -workspace StudyOS.xcworkspace \
  -scheme StudyOS \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.3.1'
