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

# Get dependencies
flutter pub get

# Generate Flutter build config
flutter build ios --config-only

# Clean derived data before building
rm -rf ~/Library/Developer/Xcode/DerivedData/* || true

# Install pods - with better error handling
cd ios

echo "Removing old Pods..."
rm -rf Pods/ Podfile.lock || true

echo "Installing CocoaPods..."
pod install || {
  echo "Pod install failed, trying with repo update..."
  pod install --repo-update
}

cd ..

echo "=== Xcode Cloud Post Clone Complete ==="