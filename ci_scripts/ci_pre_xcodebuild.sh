#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOSITORY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_SCRIPT="$REPOSITORY_ROOT/ios/ci_scripts/ci_pre_xcodebuild.sh"

if [ -f "$IOS_SCRIPT" ]; then
  sh "$IOS_SCRIPT"
else
  echo "No iOS pre-xcodebuild script found at $IOS_SCRIPT"
fi
