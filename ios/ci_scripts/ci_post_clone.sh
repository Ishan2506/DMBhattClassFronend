#!/bin/sh
set -e

echo "=== Xcode Cloud Post Clone Start ==="

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"

export PATH="$HOME/flutter/bin:$PATH"

flutter --version

# Download Flutter iOS artifacts
flutter precache --ios

# Get dependencies
flutter pub get

# Generate Flutter build config
flutter build ios --config-only

# Install pods - skip repo update to avoid CDN issues
cd ios
pod install --repo-update=false || pod install
cd ..

echo "=== Xcode Cloud Post Clone Complete ==="