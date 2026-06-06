#!/bin/sh
set -e

echo "=== Xcode Cloud Post Clone Start ==="

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter (Clean clone with single-branch and blobless filters to avoid timeouts)
rm -rf "$HOME/flutter"
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable --single-branch --filter=blob:none "$HOME/flutter"

export PATH="$HOME/flutter/bin:$PATH"

# Disable Swift Package Manager globally for the runner
flutter config --no-enable-swift-package-manager

flutter --version

# Download Flutter iOS artifacts
flutter precache --ios

# Match the local recovery steps used before archiving from Xcode.
echo "Cleaning Flutter build outputs..."
flutter clean

echo "Resetting iOS CocoaPods state..."
rm -rf ios/Pods ios/.symlinks ios/Flutter/Flutter.podspec

# Get dependencies and regenerate Flutter's iOS configuration.
flutter pub get

flutter build ios --config-only

# Clean derived data before building
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

# Install pods after Flutter has regenerated Generated.xcconfig.
cd ios

echo "Installing CocoaPods..."
pod install || {
  echo "Pod install failed, trying with repo update..."
  pod install --repo-update
}

cd ..

echo "=== Xcode Cloud Post Clone Complete ==="
