#!/bin/sh

echo "=== Xcode Cloud Post-Xcodebuild Start ==="

# Print build artifacts location
if [ -d "$CI_BUILD_DIR" ]; then
  echo "Build directory: $CI_BUILD_DIR"
  ls -la "$CI_BUILD_DIR" || true
fi

echo "=== Xcode Cloud Post-Xcodebuild Complete ==="
