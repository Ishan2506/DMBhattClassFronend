#!/bin/sh
set -e

# Ensure we're in the repository root
if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
  cd "$CI_PRIMARY_REPOSITORY_PATH"
fi

# Install Flutter
rm -rf "$HOME/flutter"
echo "Cloning Flutter repository..."
if git clone https://github.com/flutter/flutter.git --depth 1 --branch stable --single-branch "$HOME/flutter"; then
  echo "Flutter cloned successfully"
else
  echo "Clone failed, retrying..."
  git clone https://github.com/flutter/flutter.git --depth 1 --branch stable --single-branch "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"
export FLUTTER_HOME="$HOME/flutter"
which flutter || (echo "Flutter not found in PATH" && exit 1)

echo "Flutter version:"
flutter --version

echo "Disabling Swift Package Manager to avoid Xcode Cloud CI failures"
flutter config --no-enable-swift-package-manager

echo "Getting dependencies"
flutter pub get

echo "Precaching Flutter iOS artifacts..."
flutter precache --ios

# Run a config-only iOS build. This is the step that fully generates the
# iOS plugin set (Flutter/Generated.xcconfig, the .symlinks/plugins entries,
# and GeneratedPluginRegistrant) that `pod install` reads from. Without it,
# `flutter pub get` alone leaves CocoaPods with an incomplete plugin list,
# which is why pods like connectivity_plus were never installed and the
# archive failed with "Module 'connectivity_plus' not found".
echo "Generating iOS build configuration..."
flutter build ios --config-only --release --no-codesign

echo "Installing CocoaPods"
if [ -d "ios" ]; then
  cd ios
  # Force a clean pod install so a stale Pods/Podfile.lock can never mask a
  # newly added plugin.
  rm -rf Pods Podfile.lock
  pod install --repo-update
  cd ..
else
  echo "Error: ios directory not found"
  exit 1
fi