#!/bin/sh
set -e

echo "=== Xcode Cloud Pre-Xcodebuild Start ==="

cd "$CI_PRIMARY_REPOSITORY_PATH"

export PATH="$HOME/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Dart version:"
dart --version

echo "CocoaPods version:"
pod --version

echo "=== Xcode Cloud Pre-Xcodebuild Complete ==="
