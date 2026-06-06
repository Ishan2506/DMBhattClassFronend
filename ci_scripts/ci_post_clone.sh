#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOSITORY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_SCRIPT="$REPOSITORY_ROOT/ios/ci_scripts/ci_post_clone.sh"

if [ -f "$IOS_SCRIPT" ]; then
  sh "$IOS_SCRIPT"
else
  echo "No iOS post-clone script found at $IOS_SCRIPT"
fi
