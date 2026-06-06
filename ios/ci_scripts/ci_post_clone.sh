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

# Install pods
cd ios
pod install
cd ..

echo "=== Xcode Cloud Post Clone Complete ==="